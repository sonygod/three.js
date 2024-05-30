import three.shadernode.ShaderNode;

class BRDF_Lambert {
    public static function new() {
        return ShaderNode.tslFn(function(inputs) {
            return inputs.diffuseColor.mul(1 / Math.PI); // punctual light
        });
    }
}