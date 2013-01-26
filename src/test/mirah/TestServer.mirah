package org.kaspernj.busa

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
  def testServer
    path = "#{java::io::File.new(".").getAbsolutePath}/src/main/mirah/pages"
    inst = self
    busa = Busa.new("port" => "8085", "debug" => "false")
    
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
      http.setPort(Integer.new(8085))
      http.connect
      #http.setDebug(Boolean.TRUE)
      
      puts "Sending GET-request."
      
      timeout = Timeout.new(2, nil)
      timeout.on_interrupt do
        puts "Interrupting - stopping Busa before actually sending interrupt."
        busa.stop
      end
      
      timeout.run_timeout do
        res = http.get("debug_system.erb")
        raise "Invalid content: '#{res.getBody}'." if !res.getBody.contains("<title>Test-side</title>") or !res.getBody.contains("</html>") or !res.getBody.contains("<html>")
      end
      
      timeout.run_timeout do
        res = http.get("test.mirah.erb")
        raise "Invalid content: '#{res.getBody}'." if !res.getBody.contains("<title>This is a test.</title>") or !res.getBody.contains("</html>") or !res.getBody.contains("<html>")
      end
      
      timeout.run_timeout do
        res = http.get("test_file.html")
        raise "Invalid content: '#{res.getBody}'." if !res.getBody.contains("<title>Static file test</title>") or !res.getBody.contains("</html>") or !res.getBody.contains("<html>")
      end
      
      timeout.run_timeout do
        res = http.get("file_that_does_not_exist.html")
        Assert.assertEquals(404, res.getStatusCode)
      end
    ensure
      busa.stop
    end
    
    busa.join
    
    return
  end
end