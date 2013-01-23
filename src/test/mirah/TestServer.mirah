package org.kaspernj.busa

import org.junit.Test
import org.kaspernj.mirah.stdlib.timeout.*
import org.kaspernj.fw.httpbrowser.HttpBrowser
import org.kaspernj.busa.*

class TestServer
  $Test
  def testServer
    path = "#{java::io::File.new(".").getAbsolutePath}/src/main/mirah/pages"
    
    busa = Busa.new("port" => "8085", "debug" => "true", "doc_root" => path)
    
    thread_busa = Thread.new do
      puts "Starting listening for Busa."
      
      begin
        busa.listen
      ensure
        puts "Stopped listening for Busa."
      end
    end
    
    busa.connect_route do |request|
      if request.url.equals("/debug_system.erb")
        puts "Handeling!"
        
        cwriter = request.cwriter
        cwriter.write("<html>")
        cwriter.write("<head>")
        cwriter.write("<title>Test-side</title>")
        cwriter.write("</head>")
        cwriter.write("<body>")
        cwriter.write("Dette er en test.")
        cwriter.write("</body>")
        cwriter.write("</html>")
        
        return Boolean.new(true)
      end
      
      puts "Dont handle #{request.url}"
      return Boolean.new(false)
    end
    
    thread_busa.start
    
    begin
      puts "Connecting to Busa."
      http = HttpBrowser.new
      http.setHost("localhost")
      http.setPort(Integer.new(8085))
      http.connect
      
      puts "Sending GET-request."
      
      timeout = Timeout.new(2, nil)
      timeout.on_interrupt do
        puts "Interrupting - stopping Busa before actually sending interrupt."
        busa.stop
      end
      
      timeout.run_timeout do
        res = http.get("debug_system.erb")
        puts "Result: #{res.getBody}"
      end
    ensure
      puts "Stopping busa."
      busa.stop
    end
    
    busa.join
    
    return
  end
end