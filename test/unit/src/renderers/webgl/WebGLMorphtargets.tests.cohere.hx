package;

import js.QUnit;

class WebGLMorphtargetsTest {
    public static function test() : Void {
        var module = QUnit.module("Renderers");
        var webGLModule = module.module("WebGL");

        webGLModule.module("WebGLMorphtargets", function () {
            // INSTANCING
            QUnit.todo("Instancing", function (assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            // PUBLIC STUFF
            QUnit.todo("update", function (assert) {
                assert.ok(false, "everything's gonna be alright");
            });
        });
    }
}