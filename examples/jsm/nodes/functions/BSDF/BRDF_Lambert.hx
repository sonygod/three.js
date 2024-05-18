package three.js.examples.jsm.nodes.functions.BSDF;

import three.js.shadernode.ShaderNode;

class BRDF_Lambert {
    public static function tslFn(inputs:Dynamic):Dynamic {
        return inputs.diffuseColor.mul(1 / Math.PI); // punctual light
    }
}