package three.js.test.unit.src.extras;

import utest.Runner;
import utest.ui.Report;
import three.js.extras.PMREMGenerator;

class PMREMGeneratorTests {
  public static function main() {
    var runner = new Runner();
    runner.addCase(new PMREMGeneratorTestCase());
    Report.create(runner);
    runner.run();
  }
}

class PMREMGeneratorTestCase {
  public function new() {}

  public function testInstancing() {
    Assert.fail("everything's gonna be alright");
  }

  public function testFromScene() {
    Assert.fail("everything's gonna be alright");
  }

  public function testFromEquirectangular() {
    Assert.fail("everything's gonna be alright");
  }

  public function testFromCubemap() {
    Assert.fail("everything's gonna be alright");
  }

  public function testCompileCubemapShader() {
    Assert.fail("everything's gonna be alright");
  }

  public function testCompileEquirectangularShader() {
    Assert.fail("everything's gonna be alright");
  }

  public function testDispose() {
    Assert.fail("everything's gonna be alright");
  }
}