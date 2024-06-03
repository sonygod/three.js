import js.Browser.document;
import threejs.renderers.shaders.ShaderChunk;

class ShaderChunkTests {
    public function new() {
        moduleRenderers();
    }

    private function moduleRenderers(): Void {
        moduleShaders();
    }

    private function moduleShaders(): Void {
        moduleShaderChunk();
    }

    private function moduleShaderChunk(): Void {
        testInstancing();
    }

    private function testInstancing(): Void {
        if (js.Boot.isClass(ShaderChunk)) {
            js.Browser.console.log("ShaderChunk is defined.");
        } else {
            js.Browser.console.log("ShaderChunk is not defined.");
        }
    }
}