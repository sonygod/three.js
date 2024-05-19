Here is the equivalent Haxe code:
```
package three.test.unit.src.renderers.webgl;

import utest.Runner;
import utest.ui.Report;

class WebGLMorphtargetsTests {
    public static function addTests(runner:Runner) {
        runner.describe("Renderers", () => {
            runner.describe("WebGL", () => {
                runner.describe("WebGLMorphtargets", () => {
                    // INSTANCING
                    runner.todo("Instancing", (assert) => {
                        assert.isTrue(false, "everything's gonna be alright");
                    });

                    // PUBLIC STUFF
                    runner.todo("update", (assert) => {
                        assert.isTrue(false, "everything's gonna be alright");
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
Note that I've replaced `QUnit` with `utest`, which is a popular testing framework for Haxe. I've also replaced `export default` with a `public static function main()` entry point, which is a common pattern in Haxe. Additionally, I've used the `describe` and `todo` methods from `utest` to define the test suite.

Please note that this conversion assumes that you have already set up an Haxe project with the necessary dependencies and configurations.