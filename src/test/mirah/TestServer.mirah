package org.kaspernj.busa

import org.junit.Test
import org.kaspernj.mirah.stdlib.core.TestClass

$TestClass
class TestServer
  $Test
  def testServer
    busa = Busa.new("port" => "8085")
    busa.listen
    
    http = Httpbrowser.new
    http.setHost("localhost", 8085)
    http.connect
  end
end