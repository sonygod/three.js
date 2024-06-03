import js.Browser.document;
import three.renderers.shaders.ShaderLib;

class ShaderLibTests {
    public static function main() {
        // Shaders
        testShaders();
    }

    private static function testShaders() {
        // Instancing
        testInstancing();
    }

    private static function testInstancing() {
        trace("Testing Instancing...");
        var shaderLib = ShaderLib.getInstance();
        trace(shaderLib != null ? "ShaderLib is defined." : "ShaderLib is not defined.");
    }
}