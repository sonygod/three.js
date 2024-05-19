package three.test.unit.src.renderers.webgl;

import utest.Runner;
import utest.ui.Report;

class WebGLAttributesTest {
    public function new() {}

    public static function main() {
        var runner = new Runner();
        runner.addCase(new WebGLAttributesTest());
        Report.create(runner);
        runner.run();
    }

    public function testWebGLAttributes():Void {
        var test = new Test("WebGLAttributes");

        // INSTANCING
        test.todo("Instancing", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC STUFF
        test.todo("get", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        test.todo("remove", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        test.todo("update", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });
    }
}