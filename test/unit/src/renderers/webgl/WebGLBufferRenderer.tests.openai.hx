import haxe.unit.TestCase;

class WebGLBufferRendererTests {
    public function new() {}

    public function testRenderers() {
        testCase("WebGL", function() {
            testCase("WebGLBufferRenderer", function() {
                // INSTANCING
                todo("Instancing", function(assert) {
                    assert.isTrue(false, "everything's gonna be alright");
                });

                // PUBLIC STUFF
                todo("setMode", function(assert) {
                    assert.isTrue(false, "everything's gonna be alright");
                });

                todo("render", function(assert) {
                    assert.isTrue(false, "everything's gonna be alright");
                });

                todo("renderInstances", function(assert) {
                    assert.isTrue(false, "everything's gonna be alright");
                });
            });
        });
    }
}

Note that I've replaced the QUnit API with the Haxe unit testing framework, which is similar in concept. I've also removed the imports and exports, as Haxe has a different module system. Additionally, I've replaced the `QUnit.module` calls with `testCase` calls, which is the equivalent in Haxe.

Note that in Haxe, you'll need to create a `TestRunner` class to run these tests. Here's an example:

class TestRunner {
    public static function main() {
        var runner = new haxe.unit.TestRunner();
        runner.add(new WebGLBufferRendererTests());
        runner.run();
    }
}