package three.test.unit.src.renderers.webgl;

import three.renderers.webgl.WebGLProgram;

class WebGLProgramTests {
    public function new() {}

    public static function main() {
        var testSuite = new haxe.unit.TestSuite();

        testSuite.addTestCase(new WebGLProgramTest());

        haxe.unit.TestRunner.run(testSuite);
    }
}

class WebGLProgramTest {
    public function new() {}

    public function testAll() {
        // INSTANCING
        todo("Instancing", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PROPERTIES
        todo("uniforms", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        todo("attributes", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC STUFF
        todo("getUniforms", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        todo("getAttributes", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        todo("destroy", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });
    }
}

// We need to define the todo function, similar to QUnit.todo
function todo(name:String, callback:Void->Void) {
    trace("TODO: " + name);
    callback();
}