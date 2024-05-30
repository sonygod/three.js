package three.js.examples.jsm.nodes.functions.BSDF;

import haxe.ds.Vector;
import three.js.shadernode.ShaderNode;

class DFGApprox {
    public static function tslFn(roughness:Float, dotNV:Vector<Float>) : Vector<Float> {
        var c0:Vector<Float> = Vector.fromArray([-1, -0.0275, -0.572, 0.022]);
        var c1:Vector<Float> = Vector.fromArray([1, 0.0425, 1.04, -0.04]);

        var r:Vector<Float> = c0.multiply(roughness).add(c1);

        var a004:Float = r.get(0) * r.get(0) * Math.min(-9.28 * dotNV.dotProduct(new Vector<Float>([dotNV.get(0), dotNV.get(1), dotNV.get(2)])), 1) * r.get(0) + r.get(1);

        var fab:Vector<Float> = new Vector<Float>(2);
        fab.set(0, (-1.04 * a004 + r.get(2)));
        fab.set(1, (1.04 * a004 + r.get(3)));

        return fab;
    }

    public static function main() {
        ShaderNode.registerFunction("DFGApprox", tlsFn, 2, ["roughness", "dotNV"], ["float", "vec3"], "vec2");
    }
}