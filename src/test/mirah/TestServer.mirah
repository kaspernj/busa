package org.kaspernj.busa

import java.util.ArrayList
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicInteger
import java.net.ServerSocket

import org.junit.Assert
import org.junit.Test

import org.kaspernj.mirah.stdlib.timeout.*
import org.kaspernj.fw.httpbrowser.HttpBrowser
import org.kaspernj.busa.*
import org.kaspernj.mirah.erb2mirah.Erb2mirah
import org.kaspernj.mirah.erb2mirah.Page
import org.kaspernj.mirah.erb2mirah.InstanceLoader

class TestServer
  $Test
  def testServer:void
    server = ServerSocket.new(0)
    port = server.getLocalPort
    port_str = String.valueOf(port)
    server.close
    
    path = "#{java::io::File.new(".").getAbsolutePath}/src/main/mirah/pages"
    inst = self
    busa = Busa.new("port" => port_str, "debug" => "false")
    
    thread_busa = Thread.new do
      puts "Starting listening for Busa."
      
      begin
        busa.listen
      ensure
        puts "Stopped listening for Busa."
      end
    end
    
    erb_handler = BusaHandlerErb.new("package" => "org.kaspernj.mirah.erb2mirah.generated")
    res_handler = BusaHandlerResources.new("path" => "www")
    
    busa.connect_route do |request|
      if erb_handler.handle_request(request) == Boolean.TRUE
        return Boolean.TRUE
      elsif res_handler.handle_request(request) == Boolean.TRUE
        return Boolean.TRUE
      elsif request.url.equals("/debug_system.erb")
        cwriter = request.cwriter
        cwriter.write("<html>")
        cwriter.write("<head>")
        cwriter.write("<title>Test-side</title>")
        cwriter.write("</head>")
        cwriter.write("<body>")
        cwriter.write("Dette er en test.")
        cwriter.write("</body>")
        cwriter.write("</html>")
        
        return Boolean.TRUE
      end
      
      return Boolean.FALSE
    end
    
    thread_busa.start
    
    begin
      puts "Connecting to Busa."
      http = HttpBrowser.new
      http.setHost("localhost")
      http.setPort(Integer.new(port))
      http.connect
      #http.setDebug(Boolean.TRUE)
      
      
      puts "Sending GET-request."
      
      timeout = Timeout.new(2, nil)
      
      #Stop busa when interrupting because of timeout - it is not possible to interrupt a socket-read (because Java is retarded?).
      timeout.on_interrupt do
        puts "Interrupting - stopping Busa before actually sending interrupt."
        busa.stop
      end
      
      #Test custom route.
      timeout.run_timeout do
        res = http.get("debug_system.erb")
        raise "Invalid content: '#{res.getBody}'." if !res.getBody.contains("<title>Test-side</title>") or !res.getBody.contains("</html>") or !res.getBody.contains("<html>")
      end
      
      #Test compiled ERB file.
      timeout.run_timeout do
        res = http.get("test.mirah.erb")
        raise "Invalid content: '#{res.getBody}'." if !res.getBody.contains("<title>This is a test.</title>") or !res.getBody.contains("</html>") or !res.getBody.contains("<html>")
        raise "Didnt read the test-import: '#{res.getBody}'." if !res.getBody.contains("<div>[TEST IMPORT]</div>")
      end
      
      #Test static file bundeled as resource.
      timeout.run_timeout do
        res = http.get("test_file.html")
        raise "Invalid content: '#{res.getBody}'." if !res.getBody.contains("<title>Static file test</title>") or !res.getBody.contains("</html>") or !res.getBody.contains("<html>")
      end
      
      #Test a file that does not exist.
      timeout.run_timeout do
        res = http.get("file_that_does_not_exist.html")
        Assert.assertEquals(404, res.getStatusCode)
      end
      
      #Benchmark test.
      requests_count = AtomicInteger.new(0)
      threads = ArrayList.new
      secs = 2
      amount_of_threads = 100
      time_stop = AtomicLong.new(System.currentTimeMillis + long(secs * 1000))
      
      0.upto(amount_of_threads) do |tcount|
        thread = self.thread_perf_test(time_stop, requests_count, Integer.new(port))
        threads.add(thread)
      end
      
      threads.each do |thread_i|
        Thread(thread_i).join
      end
      
      requests_count_per_second = requests_count.get / secs
      
      #Extracted to own method because of stupid Mirah verify bug :-(
      self.check_performance(requests_count_per_second)
    ensure
      busa.stop
    end
    
    busa.join
  end
  
  def check_performance(requests_count_per_second:int)
    raise "Performance problem - only #{requests_count_per_second} requests per second and expected 1000 or more." if requests_count_per_second < 1000
  end
  
  def thread_perf_test(time_stop:AtomicLong, requests_count:AtomicInteger, port:Integer)
    thread = Thread.new do
      request_urls = ["debug_system.erb", "test.mirah.erb", "test_file.html"]
      
      #puts "Spinning up thread (TimeStop: #{time_stop})."
      
      http = HttpBrowser.new
      http.setHost("localhost")
      http.setPort(port)
      http.connect
      
      begin
        while System.currentTimeMillis < time_stop.get
          request_urls.each do |request_url|
            http.get(String(request_url))
            requests_count.incrementAndGet
          end
        end
      ensure
        http.close
      end
    end
    
    thread.start
    
    return thread
  end
end