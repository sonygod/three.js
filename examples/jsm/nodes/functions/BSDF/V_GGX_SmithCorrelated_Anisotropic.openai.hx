package three.js.examples.jsm.nodes.functions.BSDF;

import three.js.math.Operator.Node;
import three.js.shader.ShaderNode;

class V_GGX_SmithCorrelated_Anisotropic {
    public static function compute(alphaT:Float, alphaB:Float, dotTV:Float, dotBV:Float, dotTL:Float, dotBL:Float, dotNV:Float, dotNL:Float):Float {
        var gv = dotNL * Math.sqrt(alphaT * dotTV * alphaT * dotTV + alphaB * dotBV * alphaB * dotBV + dotNV * dotNV);
        var gl = dotNV * Math.sqrt(alphaT * dotTL * alphaT * dotTL + alphaB * dotBL * alphaB * dotBL + dotNL * dotNL);
        var v = 0.5 / (gv + gl);
        return v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v);
    }
}