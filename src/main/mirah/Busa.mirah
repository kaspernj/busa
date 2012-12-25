package org.kaspernj.busa

import org.kaspernj.mirah.stdlib.socket.*
import java.util.HashMap

class Busa
  def initialize(args:HashMap)
    port = String(args.get("port"))
    port = "8085" if port == null
    @port = Integer.parseInt(port)
    
    @socket = TCPServer.new("0.0.0.0", @port)
    @clients = java::util::ArrayList.new
  end
  
  def port
    return @port
  end
  
  def socket
    return @socket
  end
  
  def clients
    return @clients
  end
  
  def listen
    instance = self
    
    @listen_thread = Thread.new do
      loop do
        busa_client = BusaClient.new(instance, instance.socket.accept)
        instance.clients.add(busa_client)
      end
    end
  end
  
  def join
    raise "The object is not listening." if @listen_thread == null
    @listen_thread.join
  end
end