package three.test.unit.src.renderers.webgl;

import haxe.unit.TestCase;
import three.renderers.webgl.WebGLUniforms;

class WebGLUniformsTest extends TestCase {
    public function new() {
        super();
    }

    public function testRenderers() {
        test("WebGL", () => {
            test("WebGLUniforms", () => {
                // INSTANCING
                todo("Instancing", () => {
                    assertTrue(false, 'everything\'s gonna be alright');
                });

                // PUBLIC STUFF
                todo("setValue", () => {
                    assertTrue(false, 'everything\'s gonna be alright');
                });

                todo("setOptional", () => {
                    assertTrue(false, 'everything\'s gonna be alright');
                });

                todo("upload", () => {
                    assertTrue(false, 'everything\'s gonna be alright');
                });

                todo("seqWithValue", () => {
                    assertTrue(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}