package three.test.unit.src.renderers.webgl;

import utest.Runner;
import utest.ui.Report;
import three.renderers.webgl.WebGLUniforms;

class WebGLUniformsTest {
  public static function main() {
    var runner = new Runner();
    runner.addCase(new WebGLUniformsTestCase());
    Report.create(runner);
    runner.run();
  }
}

class WebGLUniformsTestCase {
  public function new() {}

  public function testRenderers() {
    testWebGL();
  }

  private function testWebGL() {
    testWebGLUniforms();
  }

  private function testWebGLUniforms() {
    todoInstancing();
    todoSetValue();
    todoSetOptional();
    todoUpload();
    todoSeqWithValue();
  }

  private function todoInstancing() {
    utest.Assert.ok(false, "everything's gonna be alright");
  }

  private function todoSetValue() {
    utest.Assert.ok(false, "everything's gonna be alright");
  }

  private function todoSetOptional() {
    utest.Assert.ok(false, "everything's gonna be alright");
  }

  private function todoUpload() {
    utest.Assert.ok(false, "everything's gonna be alright");
  }

  private function todoSeqWithValue() {
    utest.Assert.ok(false, "everything's gonna be alright");
  }
}