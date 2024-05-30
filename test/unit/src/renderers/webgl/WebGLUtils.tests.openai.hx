import utest.Runner;
import utest.ui.Report;

class WebGLUtilsTest {
  public static function main() {
    var runner = new Runner();
    runner.addCase(new WebGLUtilsTestCase());
    Report.create(runner);
    runner.run();
  }
}

class WebGLUtilsTestCase {
  public function new() {}

  public function testInstancing() {
    // TO DO: implement instancing test
    Assert.isTrue(false, "everything's gonna be alright");
  }

  public function testConvert() {
    // TO DO: implement convert test
    Assert.isTrue(false, "everything's gonna be alright");
  }
}