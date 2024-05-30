@:jsRequire('../../shadernode/ShaderNode.js')
extern class ShaderNode {
    static function tslFn(callback:Dynamic->Dynamic):Dynamic;
}

class BRDF_Lambert {
    static function apply(inputs:Dynamic):Dynamic {
        return inputs.diffuseColor.mul(1 / Math.PI); // punctual light
    }
}

BRDF_Lambert.apply = ShaderNode.tslFn(BRDF_Lambert.apply);