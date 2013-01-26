package org.kaspernj.busa

import java.util.HashMap

#This class can automatically handle resources in certain paths to be requested seamlessly.
class BusaHandlerResources
  def initialize(args:HashMap)
    args_allowed = ["path"]
    args.keySet.each do |key|
      raise "Invalid key: '#{key}'." if !args_allowed.contains(key)
    end
    
    @path = String(args["path"])
    raise "Invalid path: '#{@path}'." if @path == nil or @path.isEmpty
    
    @cl = self.getClass.getClassLoader
  end
  
  def handle_request(request:BusaClient)
    path = "#{@path}#{request.url}"
    res = @cl.getResource(path)
    return Boolean.FALSE if res == nil
    
    file = java::io::File.new(res.toURI)
    fis = @cl.getResourceAsStream(path)
    length = int(file.length)
    bytes = byte[length]
    
    0.upto(length - 1) do |count|
      bytes[count] = byte(fis.read)
    end
    
    request.cwriter.write(bytes)
    
    return Boolean.TRUE
  end
end