import js.QUnit;
import js.ShaderLib from '../../../../../src/renderers/shaders/ShaderLib.js';

class TestShaderLib {
    static function testInstancing() {
        var shaderLib = ShaderLib.fromJSON({ foo: "bar" });
        var result = shaderLib != null;
        trace(result);
        return result;
    }
}

@:main
function main() {
    TestShaderLib.testInstancing();
}