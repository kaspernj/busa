package org.kaspernj.busa

import org.kaspernj.mirah.stdlib.socket.*

class BusaClient
  def initialize(busa:Busa, socket:TCPSocket)
    @socket = socket
    @busa = busa
    instance = self
    
    Thread.new do
      instance.handle_request
    end
  end
  
  def handle_request
    headers = {}
    
    regex = /^(GET|POST|HEAD)\s+(.+)\s+HTTP\/1\.(\d+)\s*/
    
    status_line = @socket.gets
    matcher = regex.matcher(status_line)
    
    while matcher.find
      type = matcher.group(1)
      url = matcher.group(2)
      http_version_last = matcher.group(3)
    end
  end
end