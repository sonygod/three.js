import js.QUnit;
import js.Renderers.Shaders.UniformsLib;

class TestUniformsLib {
    static function main() {
        var done : js.html.IDOMCallback = function(assert:QUnit) {
            var uniformsLib = new UniformsLib();
            assert.ok(uniformsLib != null, "UniformsLib is defined.");
        }
        QUnit.module("Renderers", function(container:Dynamic) {
            container.module("Shaders", function(container:Dynamic) {
                container.module("UniformsLib", function(container:Dynamic) {
                    container.test("Instancing", done);
                });
            });
        });
    }
}

TestUniformsLib.main();