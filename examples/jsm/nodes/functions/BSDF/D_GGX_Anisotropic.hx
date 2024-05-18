package three.js.examples.jsm.nodes.functions.BSDF;

import three.js.shadernode.ShaderNode;

class D_GGX_Anisotropic {
    static public var RECIPROCAL_PI:Float = 1.0 / Math.PI;

    public static function tslFn(alphaT:Float, alphaB:Float, dotNH:Float, dotTH:Float, dotBH:Float):Float {
        var a2:Float = alphaT * alphaB;
        var v:Vec3 = new Vec3(alphaB * dotTH, alphaT * dotBH, a2 * dotNH);
        var v2:Float = v.dot(v);
        var w2:Float = a2 / v2;

        return RECIPROCAL_PI * a2 * Math.pow(w2, 2.0);
    }

    public static function setLayout():ShaderNode {
        return new ShaderNode('D_GGX_Anisotropic', ShaderNode.FLOAT, [
            { name: 'alphaT', type: ShaderNode.FLOAT, qualifier: 'in' },
            { name: 'alphaB', type: ShaderNode.FLOAT, qualifier: 'in' },
            { name: 'dotNH', type: ShaderNode.FLOAT, qualifier: 'in' },
            { name: 'dotTH', type: ShaderNode.FLOAT, qualifier: 'in' },
            { name: 'dotBH', type: ShaderNode.FLOAT, qualifier: 'in' }
        ]);
    }
}