package three.js.test.unit.src.renderers.webgl;

import utest.Runner;
import utest.ui.Report;
import three.js.renderers.webgl.WebGLAttributes;

class WebGLAttributesTests {

  public static function main() {
    var runner = new Runner();
    runner.addCase(new WebGLAttributesTests());
    Report.create(runner);
    runner.run();
  }

  public function new() { }

  public function testInstancing():Void {
    // todo: implement instancing test
    assertTrue(false, "everything's gonna be alright");
  }

  public function testGet():Void {
    // todo: implement get test
    assertTrue(false, "everything's gonna be alright");
  }

  public function testRemove():Void {
    // todo: implement remove test
    assertTrue(false, "everything's gonna be alright");
  }

  public function testUpdate():Void {
    // todo: implement update test
    assertTrue(false, "everything's gonna be alright");
  }

}