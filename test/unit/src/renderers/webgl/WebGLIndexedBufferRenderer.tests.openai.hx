import haxe.unit.TestCase;
import three.renderers.webgl.WebGLIndexedBufferRenderer;

class WebGLIndexedBufferRendererTests extends TestCase {
    public function new() {
        super();

        test("Renderers", {
            test("WebGL", {
                test("WebGLIndexedBufferRenderer", {
                    // INSTANCING
                    todo("Instancing", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    // PUBLIC STUFF
                    todo("setMode", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    todo("setIndex", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    todo("render", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    todo("renderInstances", function(assert) {
                        assert.ok(false, "everything's gonna be alright");
                    });
                });
            });
        });
    }
}