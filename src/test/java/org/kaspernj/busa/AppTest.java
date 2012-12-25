package org.kaspernj.busa;

import org.junit.Test;
import org.kaspernj.mirah.stdlib.core.MirahTester;

public class AppTest{
  @Test
  public void doTest() throws Exception{
    MirahTester.executeMirahTestsForPackage("org.kaspernj.busa");
  }
}
