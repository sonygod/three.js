import haxe.unit.TestCase;
import three.js.renderers.shaders.ShaderChunk;

class ShaderChunkTests extends TestCase {

    public function new() {
        super();

        Tester.run({
            name: "Renderers",
            tests: [
                {
                    name: "Shaders",
                    tests: [
                        {
                            name: "ShaderChunk",
                            tests: [
                                {
                                    name: "Instancing",
                                    fn: function(assert: Assert) {
                                        assert.ok(ShaderChunk.isInstanced, 'ShaderChunk is defined.');
                                    }
                                }
                            ]
                        }
                    ]
                }
            ]
        });
    }

    public static function main() {
        var runner = new TestRunner();
        runner.add(new ShaderChunkTests());
        runner.run();
    }

}