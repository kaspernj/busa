package org.kaspernj.busa

import org.kaspernj.mirah.stdlib.socket.*

class BusaClient
  def meta; return @meta; end
  def headers; return @headers; end
  def type; return @type; end
  def url; return @url; end
  def http_version; return @http_version; end
  def cwriter; return @cwriter; end
  def socket; return @socket; end
  def headers_out; return @headers_out; end
  
  def initialize(busa:Busa, socket:TCPSocket)
    raise "Busa is null?" if busa == nil
    
    @socket = socket
    @busa = busa
    @stopped = false
    @debug = true
    @addr = socket.addr
  end
  
  def listen
    instance = self
    busa = @busa
    
    @request_thread = Thread.new do
      raise "Busa is null." if busa == nil
      
      begin
        while true
          instance.debug "Beginning new request."
          instance.handle_request
        end
      rescue => e
        if e.getClass == java::net::SocketException.class and e.getMessage.equals("Socket closed") and instance.stopped
          #ignore - socket was closed.
          instance.debug "Ignore error because the client expects to be stopped ('stop' was probably called)."
          nil
        else
          busa.handle_error(e)
          nil
        end
      end
    end
    
    @request_thread.start
  end
  
  def stopped
    return @stopped
  end
  
  #Returns true if this client is actively listening for new requests.
  def alive
    return true if @request_thread != nil and @request_thread.isAlive
    return false
  end
  
  def debug(str:String)
    puts str if @debug
  end
  
  def stop
    @stopped = true
    @socket.close
    @request_thread.interrupt if @request_thread.isAlive
  end
  
  def handle_request
    #Read and parse status line.
    regex_status_line = /^(GET|POST|HEAD)\s+(.+)\s+HTTP\/1\.(\d+)\s*/
    
    status_line = @socket.gets
    matcher = regex_status_line.matcher(status_line)
    
    raise "Could not match status header: '#{status_line}'." if !matcher.find
    
    @type = matcher.group(1)
    @url = matcher.group(2)
    @http_version = "1.#{matcher.group(3)}"
    
    
    #Read and parse headers.
    regex_header = /^(.+?): (.+)(\r\n|\n)$/
    
    @headers = {}
    @meta = {
      "METHOD" => matcher.group(1),
      "REMOTE_ADDR" => @addr.get(2),
      "REMOTE_PORT" => @addr.get(1)
    }
    
    while true
      header_str = @socket.gets
      debug "Header string: #{header_str}"
      
      break if header_str.equals("\n") or header_str.equals("\r\n")
      
      matcher = regex_header.matcher(header_str)
      
      raise "Could not match header: '#{header_str}'." if !matcher.find
      
      header_key = matcher.group(1)
      header_val = matcher.group(2)
      
      meta_key = "HTTP_#{header_key.toUpperCase}".replaceAll("-", "_")
      
      headers[header_key] = header_val
      meta[meta_key] = header_val
    end
    
    debug "Request headers: #{headers}"
    debug "Meta: #{meta}"
    
    @cwriter = BusaClientContentWriter.new(self)
    
    @headers_out = {
      "Host" => @meta["HTTP_HOST"]
    }
    
    #Figure out path to requested file.
    @busa.dispatch(self)
    
    if @http_version.equals("1.1") and @meta.containsKey("HTTP_CONNECTION") and String(@meta["HTTP_CONNECTION"]).toLowerCase.equals("keep-alive")
      BusaClientResultWriterHttp11.new(self).run
    else
      raise "Unknown HTTP version: '#{@http_version}'."
    end
  end
end