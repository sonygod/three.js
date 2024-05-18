package three.js.examples.jsm.nodes.functions.BSDF;

import three.math.OperatorNode;
import three.shadernode.ShaderNode;

class V_GGX_SmithCorrelated_Anisotropic {
    public static function compute(alphaT:Float, alphaB:Float, dotTV:Float, dotBV:Float, dotTL:Float, dotBL:Float, dotNV:Float, dotNL:Float):Float {
        var gv = dotNL * new Vec3(alphaT * dotTV, alphaB * dotBV, dotNV).length();
        var gl = dotNV * new Vec3(alphaT * dotTL, alphaB * dotBL, dotNL).length();
        var v = (0.5 / (gv + gl));
        return v > 1.0 ? 1.0 : (v < 0.0 ? 0.0 : v);
    }
}

class V_GGX_SmithCorrelated_AnisotropicShaderNode extends ShaderNode {
    public function new() {
        super("V_GGX_SmithCorrelated_Anisotropic", "float", [
            { name: "alphaT", type: "float", qualifier: "in" },
            { name: "alphaB", type: "float", qualifier: "in" },
            { name: "dotTV", type: "float", qualifier: "in" },
            { name: "dotBV", type: "float", qualifier: "in" },
            { name: "dotTL", type: "float", qualifier: "in" },
            { name: "dotBL", type: "float", qualifier: "in" },
            { name: "dotNV", type: "float", qualifier: "in" },
            { name: "dotNL", type: "float", qualifier: "in" }
        ]);
    }
}