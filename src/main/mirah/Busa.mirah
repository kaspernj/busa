package org.kaspernj.busa

import org.kaspernj.mirah.stdlib.socket.*
import org.kaspernj.mirah.stdlib.file.*
import org.kaspernj.mirah.stdlib.thread.*

import java.util.HashMap

interface ConnectRouteInterface do
  def run(client:BusaClient):Object; end
end

class Busa
  def initialize(args:HashMap)
    port = String(args.get("port"))
    port = "8085" if port == null
    @port = Integer.parseInt(port)
    
    @doc_root = String.valueOf(args[:doc_root])
    raise "Invalid 'doc_root' was given: '#{@doc_root}'." if @doc_root == nil or !File.exists?(@doc_root)
    
    puts "Opening port."
    @socket = TCPServer.new("0.0.0.0", @port)
    
    @clients_mutex = Mutex.new
    @clients = java::util::ArrayList.new
    @stopped = false
    @debug = true
    
    @route_blks = java::util::ArrayList.new
  end
  
  def listen
    instance = self
    socket = @socket
    clients = @clients
    
    puts "Starting listen-thread."
    @listen_thread = Thread.new do
      begin
        while true
          puts "Waiting for new client."
          socket_client = socket.accept
          
          puts "Client accepted - starting new BusaClient."
          busa_client = BusaClient.new(instance, socket_client)
          clients.add(busa_client)
          
          busa_client.listen
        end
      rescue => e
        if e.getClass == java::net::SocketException.class and e.getMessage.equals("Socket closed") and instance.stopped
          instance.debug "Ignore socket close error because we expect to be closed."
          nil
        else
          instance.handle_error(e)
          nil
        end
      end
    end
    
    @listen_thread.start
  end
  
  def debug(str:String)
    puts str if @debug
  end
  
  def stopped
    return @stopped
  end
  
  def stop
    @stopped = true
    
    @listen_thread.interrupt
    @clients.each do |client_obj|
      client = BusaClient(client_obj)
      
      debug "Stopping client: #{client}"
      client.stop
    end
    
    @socket.close
  end
  
  def join
    raise "The object is not listening." if @listen_thread == null
    @listen_thread.join
  end
  
  def handle_error(e:Exception)
    puts "Error occurred: #{e.getMessage}"
    e.printStackTrace
  end
  
  def connect_route(blk:ConnectRouteInterface)
    @route_blks.add(blk)
  end
  
  def dispatch(client:BusaClient)
    @route_blks.each do |route_blk_obj|
      route_blk = ConnectRouteInterface(route_blk_obj)
      
      res = route_blk.run(client)
      found_route = false
      
      if res.getClass == Boolean.class and res
        found_route = true
      end
      
      if found_route
        debug "Request with path '#{client.url}' was handeled by route."
        client.cwriter.done = true
        break
      end
    end
  end
end