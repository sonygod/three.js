Here is the equivalent Haxe code:
```
package three.test.unit.src.renderers.webgl;

import utest.Runner;
import utest.ui.Report;

class WebGLClippingTests {
  public function new() {}

  public static function addTests(runner:Runner) {
    runner.describe("Renderers", () -> {
      runner.describe("WebGL", () -> {
        runner.describe("WebGLClipping", () -> {
          // INSTANCING
          runner.test("Instancing", () -> {
            assert(false, "everything's gonna be alright");
          });

          // PUBLIC STUFF
          runner.test("init", () -> {
            assert(false, "everything's gonna be alright");
          });

          runner.test("beginShadows", () -> {
            assert(false, "everything's gonna be alright");
          });

          runner.test("endShadows", () -> {
            assert(false, "everything's gonna be alright");
          });

          runner.test("setState", () -> {
            assert(false, "everything's gonna be alright");
          });
        });
      });
    });
  }

  public static function main() {
    var runner = new Runner();
    addTests(runner);
    Report.create(runner);
    runner.run();
  }
}
```
Note that I've used the `utest` library, which is a popular testing framework for Haxe. I've also assumed that the `assert` function is a simple assertion function that takes a boolean value and a string message as arguments. If you're using a different assertion library, you may need to modify the code accordingly. Additionally, I've removed the `export default` statement, as it's not necessary in Haxe.