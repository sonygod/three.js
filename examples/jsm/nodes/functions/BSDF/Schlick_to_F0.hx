package three.js.examples.jm.nodes.functions.BSDF;

import_shader_node.ShaderNode;

class Schlick_to_F0 {
    public static function schlckToFO(f:Vec3, f90:Float, dotVH:Float):Vec3 {
        var x:Float = 1 - dotVH;
        x = Math.max(0, Math.min(x, 0.9999));
        var x2:Float = x * x;
        var x5:Float = x2 * x2 * x;

        return (f - new Vec3(f90 * x5)) / (1 - x5);
    }
}