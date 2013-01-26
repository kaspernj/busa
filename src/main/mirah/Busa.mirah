package org.kaspernj.busa

import org.kaspernj.mirah.stdlib.socket.*
import org.kaspernj.mirah.stdlib.file.*
import org.kaspernj.mirah.stdlib.thread.*

import java.util.ArrayList
import java.util.HashMap
import java.util.concurrent.atomic.AtomicBoolean

interface ConnectRouteInterface do
  def run(client:BusaClient):Object; end
end

class Busa
  def initialize(args:HashMap)
    allowed_args = ["debug", "port"]
    args.keySet.each do |key|
      raise "Invalid key: '#{key}'." if !allowed_args.contains(key)
    end
    
    port = String(args.get("port"))
    port = "8085" if port == null
    @port = Integer.parseInt(port)
    
    debug "Opening port."
    @socket = TCPServer.new("0.0.0.0", @port)
    
    @clients_mutex = Mutex.new
    @clients = ArrayList.new
    @stopped = false
    @debug = Boolean.valueOf(String(args["debug"]))
    
    @route_blks = ArrayList.new
  end
  
  def listen
    instance = self
    socket = @socket
    clients = @clients
    
    debug "Starting listen-thread."
    @listen_thread = Thread.new do
      begin
        while true
          instance.debug "Waiting for new client."
          socket_client = socket.accept
          
          instance.debug "Client accepted - starting new BusaClient."
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
    inst = self
    found_route = AtomicBoolean.new(false)
    
    @route_blks.each do |route_blk_obj|
      route_blk = ConnectRouteInterface(route_blk_obj)
      res = route_blk.run(client)
      
      if res.getClass == Boolean.class and res == Boolean.TRUE
        found_route.set(true)
      end
      
      if found_route.get
        inst.debug "Request with path '#{client.url}' was handeled by route."
        break
      end
    end
    
    if !found_route.get
      client.cwriter.write("URL could not be found: '#{client.url}'.")
    end
    
    client.cwriter.done = true
  end
end