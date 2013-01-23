package org.kaspernj.busa

import org.kaspernj.mirah.stdlib.socket.*

class BusaClientResultWriterHttp11
  def initialize(client:BusaClient)
    @client = client
    @socket = TCPSocket(@client.socket)
    @headers_out = @client.headers_out
    
    @headers_out["Connection"] = "Keep-Alive"
    @headers_out["Keep-Alive"] = "timeout=15, max=30"
    @headers_out["Transfer-Encoding"] = "chunked"
  end
  
  def run
    @socket.write("HTTP/1.1 200 OK\n")
    
    @headers_out.keySet.each do |key|
      puts "Sending header: '#{key}: #{@headers_out[key]}'."
      @socket.write("#{key}: #{@headers_out[key]}\n")
    end
    
    @socket.write("\n")
    socket = @socket
    
    @client.cwriter.each do |bytes_obj|
      bytes = byte[].cast(bytes_obj)
      length = int(bytes.length)
      length_str = Integer.toString(length, 16)
      
      socket.write("#{length_str}\n")
      socket.write(bytes)
      socket.write("\n")
      
      nil
    end
    
    @socket.write("0\n\n")
  end
end