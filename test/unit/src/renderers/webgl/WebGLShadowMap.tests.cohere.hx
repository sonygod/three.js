package;

import js.QUnit;

class WebGLShadowMapTest {
    public static function main() {
        var module = QUnit.module("Renderers");
        var webGLModule = module.module("WebGL");

        webGLModule.module("WebGLShadowMap", function() {
            // INSTANCING
            QUnit.todo("Instancing", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            // PUBLIC STUFF
            QUnit.todo("render", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });
        });
    }
}