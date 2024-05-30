package three.js.examples.jsm.nodes.functions.BSDF;

import haxe.ds.Vector;
import shaderNode.ShaderNode;

class D_GGX_Anisotropic {
    static inline var RECIPROCAL_PI:Float = 1 / Math.PI;

    public static function tslFn(alphaT:Float, alphaB:Float, dotNH:Float, dotTH:Float, dotBH:Float):Float {
        var a2:Float = alphaT * alphaB;
        var v:Vector<Float> = Vector.fromArray([alphaB * dotTH, alphaT * dotBH, a2 * dotNH]);
        var v2:Float = v.dot(v);
        var w2:Float = a2 / v2;

        return RECIPROCAL_PI * a2 * w2 * w2;
    }

    public static function create():ShaderNode {
        return new ShaderNode('D_GGX_Anisotropic', 'float', [
            { name: 'alphaT', type: 'float', qualifier: 'in' },
            { name: 'alphaB', type: 'float', qualifier: 'in' },
            { name: 'dotNH', type: 'float', qualifier: 'in' },
            { name: 'dotTH', type: 'float', qualifier: 'in' },
            { name: 'dotBH', type: 'float', qualifier: 'in' }
        ], tslFn);
    }
}