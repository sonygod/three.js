package;

import js.QUnit;

class WebGLShaderTest {
    public static function main() {
        var module = QUnit.module("Renderers");
        var webGLModule = module.module("WebGL");
        var webGLShaderModule = webGLModule.module("WebGLShader");

        // INSTANCING
        webGLShaderModule.todo("Instancing", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });
    }
}