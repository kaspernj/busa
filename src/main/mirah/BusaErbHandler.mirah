package org.kaspernj.busa

import org.kaspernj.mirah.erb2mirah.Erb2mirah
import org.kaspernj.mirah.erb2mirah.Page
import org.kaspernj.mirah.erb2mirah.InstanceLoader

import java.util.HashMap

class BusaErbHandler
  def initialize(args:HashMap)
    @package = String(args["package"])
    raise "Invalid package: '#{args["package"]}'." if @package == nil or @package.isEmpty
  end
  
  def handle_request(request:BusaClient):Boolean
    path_without_starting_slash = request.url.substring(1, request.url.length)
    classname = Erb2mirah.classname_for_path(path_without_starting_slash)
    
    begin
      clazz = Class.forName("#{@package}.#{classname}")
    rescue ClassNotFoundException
      #The path is not compatible with the classes in the given package.
      return Boolean.FALSE
    end
    
    page = Page(InstanceLoader.load(clazz))
    self.connect_output(page, request.cwriter)
    page.run_code
    
    return Boolean.TRUE
  end
  
  #Because of some bug in Mirah, this needs to be in a method for itself.
  def connect_output(page:Page, cwriter:BusaClientContentWriter)
    raise "Page was null." if page == nil
    raise "ContentWriter was null." if cwriter == nil
    
    page.connect_output do |str|
      puts "Got output: '#{str}'."
      cwriter.write(str)
    end
  end
end