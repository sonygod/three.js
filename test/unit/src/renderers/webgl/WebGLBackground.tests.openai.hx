import utest.Runner;
import utest.ui.Report;

class WebGLBackgroundTests {
  public static function main() {
    var runner = new Runner();
    runner.addCase(new WebGLBackgroundTest());
    Report.create(runner);
    runner.run();
  }
}

class WebGLBackgroundTest {
  public function new() {}

  public function testInstancing() {
    // todo: implement instancing test
    Assert.isTrue(false, "everything's gonna be alright");
  }

  public function testGetClearColor() {
    // todo: implement getClearColor test
    Assert.isTrue(false, "everything's gonna be alright");
  }

  public function testSetClearColor() {
    // todo: implement setClearColor test
    Assert.isTrue(false, "everything's gonna be alright");
  }

  public function testGetClearAlpha() {
    // todo: implement getClearAlpha test
    Assert.isTrue(false, "everything's gonna be alright");
  }

  public function testSetClearAlpha() {
    // todo: implement setClearAlpha test
    Assert.isTrue(false, "everything's gonna be alright");
  }

  public function testRender() {
    // todo: implement render test
    Assert.isTrue(false, "everything's gonna be alright");
  }
}