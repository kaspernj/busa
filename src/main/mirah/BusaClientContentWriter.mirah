package org.kaspernj.busa

interface ByteBlockInterface do
  def run(bytes:byte[]):void; end
end

class BusaClientContentWriter
  def done; return @done; end
  def bbuf; return @bbuf; end
  
  def initialize(client:BusaClient)
    @client = client
    @bbuf = java::util::ArrayList.new
    @done = false
    @pos = 0
    @size = 2048
  end
  
  def write(bytes:byte[])
    @bbuf.add(bytes)
  end
  
  def write(str:String)
    self.write(str.getBytes)
  end
  
  def each(blk:ByteBlockInterface)
    while @done and !@bbuf.isEmpty
      ele = byte[].cast(@bbuf.get(0))
      @bbuf.remove(ele)
      blk.run(ele)
    end
    
    puts "Done with each!"
  end
  
  def done=(newdone:boolean)
    @done = newdone
  end
end