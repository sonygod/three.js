package three.test.unit.src.renderers.webgl;

import three.renderers.webgl.WebGLProgram;
import utest Runner;
import utest.ui.Report;

class WebGLProgramTests {
    public static function main() {
        var runner = new Runner();
        runner.addCase(new WebGLProgramTests());
        Report.create(runner);
        runner.run();
    }

    public function new() {}

    public function testWebGLProgram() {
        utest.Assert.notNull(WebGLProgram, "WebGLProgram should be available");

        // INSTANCING
        todo("Instancing", function(assert:utest.Assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PROPERTIES
        todo("uniforms", function(assert:utest.Assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        todo("attributes", function(assert:utest.Assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC STUFF
        todo("getUniforms", function(assert:utest.Assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        todo("getAttributes", function(assert:utest.Assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        todo("destroy", function(assert:utest.Assert) {
            assert.ok(false, "everything's gonna be alright");
        });
    }
}