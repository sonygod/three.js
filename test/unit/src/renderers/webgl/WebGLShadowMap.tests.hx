import haxe.unit.TestCase;
import haxe.unit.TestRunner;

class WebGLShadowMapTests {
    public static function main() {
        var runner = new TestRunner();
        runner.add(new WebGLShadowMapTestCase());
        runner.run();
    }
}

class WebGLShadowMapTestCase extends TestCase {
    public function new() {
        super();
    }

    public function testRenderers() {
        test("WebGL", () => {
            test("WebGLShadowMap", () => {
                // INSTANCING
                todo("Instancing", () => {
                    assertEquals(false, true, "everything's gonna be alright");
                });

                // PUBLIC STUFF
                todo("render", () => {
                    assertEquals(false, true, "everything's gonna be alright");
                });
            });
        });
    }
}