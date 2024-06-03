import js.Browser.document;
import js.html.QUnit;
import three.js.renderers.shaders.UniformsLib;

class UniformsLibTests {
    public function new() {
        QUnit.module("Renderers", () -> {
            QUnit.module("Shaders", () -> {
                QUnit.module("UniformsLib", () -> {
                    QUnit.test("Instancing", function(assert: QUnit.Assert) {
                        assert.ok(UniformsLib.exists, "UniformsLib is defined.");
                    });
                });
            });
        });
    }
}