package three.js.examples.jsm.nodes.functions.BSDF;

import shadernode.ShaderNode;

class Schlick_to_F0 {
    public static function calculate(f:Vec3, f90:Float, dotVH:Float):Vec3 {
        var x = 1.0 - dotVH;
        x = Math.max(x, 0.0);
        var x2 = x * x;
        var x5 = x2 * x2 * x;
        x5 = Math.min(x5, 0.9999);
        return (f - new Vec3(f90) * x5) / (1.0 - x5);
    }
}