package;

import js.QUnit;

class WebGLBufferRendererTest {
    static public function test() : Void {
        var module = QUnit.module("Renderers");
        var webGLModule = module.module("WebGL");
        var webGLBufferRendererModule = webGLModule.module("WebGLBufferRenderer");

        // INSTANCING
        webGLBufferRendererModule.todo("Instancing", function() {
            // TODO: Implement test
            QUnit.ok(false, "everything's gonna be alright");
        });

        // PUBLIC STUFF
        webGLBufferRendererModule.todo("setMode", function() {
            // TODO: Implement test
            QUnit.ok(false, "everything's gonna be alright");
        });

        webGLBufferRendererModule.todo("render", function() {
            // TODO: Implement test
            QUnit.ok(false, "everything's gonna be alright");
        });

        webGLBufferRendererModule.todo("renderInstances", function() {
            // TODO: Implement test
            QUnit.ok(false, "everything's gonna be alright");
        });
    }
}