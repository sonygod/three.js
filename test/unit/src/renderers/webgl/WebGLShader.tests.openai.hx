import utest.Runner;
import utest.ui.Report;

class WebGLShaderTests {
  public static function main() {
    var runner = new Runner();
    runner.addCase(new WebGLShaderTestCase());
    Report.create(runner);
    runner.run();
  }
}

class WebGLShaderTestCase {
  public function new() {}

  public function testInstancing() {
    // TODO: implement instancing test
    Assert.isTrue(false, 'everything\'s gonna be alright');
  }
}