package;

import js.QUnit;

class TestModule {
    static public function main() {
        var module = QUnit.module("Renderers");
        var webGLModule = module.module("WebGL");
        var webGLLightsModule = webGLModule.module("WebGLLights");

        // INSTANCING
        webGLLightsModule.todo("Instancing", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC STUFF
        webGLLightsModule.todo("setup", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        webGLLightsModule.todo("state", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });
    }
}