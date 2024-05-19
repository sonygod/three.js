package three.test.unit.src.renderers.webgl;

import utest.Runner;
import utest.ITest;

class WebGLObjectsTest {

    public function new() {}

    public static function main() {
        var runner = new Runner();
        runner.addCase(new WebGLObjectsTest());
        utest.ui.Report.create(runner);
        runner.run();
    }

    public function testWebGLObjects():Void {
        test("Instancing", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        test("update", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        test("clear", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });
    }
}