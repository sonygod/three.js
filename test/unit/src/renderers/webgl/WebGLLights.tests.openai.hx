package three.test.unit.src.renderers.webgl;

import three.renderers.webgl.WebGLLights;

class WebGLLightsTest {
    public function new() {}

    public static function main() {
        Tester.module("Renderers", () => {
            Tester.module("WebGL", () => {
                Tester.module("WebGLLights", () => {
                    // INSTANCING
                    Tester.todo("Instancing", (assert) => {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    // PUBLIC STUFF
                    Tester.todo("setup", (assert) => {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    Tester.todo("state", (assert) => {
                        assert.ok(false, "everything's gonna be alright");
                    });
                });
            });
        });
    }
}