import three.js.examples.jsm.nodes.functions.BSDF.OperatorNode;
import three.js.examples.jsm.nodes.functions.BSDF.MathNode;
import three.js.examples.jsm.nodes.functions.BSDF.ShaderNode;

class V_GGX_SmithCorrelated {
    static function main(alpha:Float, dotNL:Float, dotNV:Float):Float {
        var a2 = Math.pow(alpha, 2.0);

        var gv = dotNL * Math.sqrt(a2 + (1.0 - a2) * Math.pow(dotNV, 2.0));
        var gl = dotNV * Math.sqrt(a2 + (1.0 - a2) * Math.pow(dotNL, 2.0));

        return 0.5 / Math.max(gv + gl, MathNode.EPSILON);
    }
}

ShaderNode.tslFn(V_GGX_SmithCorrelated.main, {
    name: 'V_GGX_SmithCorrelated',
    type: 'float',
    inputs: [
        { name: 'alpha', type: 'float' },
        { name: 'dotNL', type: 'float' },
        { name: 'dotNV', type: 'float' }
    ]
});