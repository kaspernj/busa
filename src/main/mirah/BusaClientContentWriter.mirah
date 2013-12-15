package org.kaspernj.busa

import mirah.stdlib.Array
import java.nio.ByteBuffer
import java.util.ArrayList

interface ByteBlockInterface do
  def run(bytes:byte[]):void; end
end

class BusaClientContentWriter
  def done; return @done; end
  def bbuf; return @bbuf; end
  
  def initialize(client:BusaClient)
    @client = client
    @bbuf = ArrayList.new
    @done = false
    @pos = 0
    @size = 4096
  end
  
  def write(bytes:byte[])
    @bbuf.add(bytes)
  end
  
  def write(str:String)
    self.write(str.getBytes)
  end
  
  def each(blk:ByteBlockInterface)
    send = ArrayList.new
    send_size = 0
    
    while @done and !@bbuf.isEmpty
      bytes_from_arr = byte[].cast(@bbuf.get(0))
      @bbuf.remove(bytes_from_arr)
      send.add(bytes_from_arr)
      send_size += bytes_from_arr.length
      
      if send_size >= @size
        self.send_bytes(blk, send, send_size)
        send.clear
        send_size = 0
      end
    end
    
    self.send_bytes(blk, send, send_size) if send_size > 0
  end
  
  def send_bytes(blk:ByteBlockInterface, send_arr:ArrayList, send_size:int):void
    byte_buffer = ByteBuffer.allocate(send_size)
    
    send_arr.each do |bytes|
      byte_buffer.put(byte[].cast(bytes))
    end
    
    blk.run(byte_buffer.array)
  end
  
  def done=(newdone:boolean)
    @done = newdone
  end
end