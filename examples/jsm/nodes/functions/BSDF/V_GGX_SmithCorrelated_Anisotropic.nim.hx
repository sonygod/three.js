import three.math.OperatorNode;
import three.shadernode.ShaderNode;

// https://google.github.io/filament/Filament.md.html#materialsystem/anisotropicmodel/anisotropicspecularbrdf

class V_GGX_SmithCorrelated_Anisotropic {
    public var name: String = "V_GGX_SmithCorrelated_Anisotropic";
    public var type: String = "float";
    public var inputs: Array<{ name: String, type: String, qualifier: String }>;

    public function new() {
        this.inputs = [
            { name: "alphaT", type: "float", qualifier: "in" },
            { name: "alphaB", type: "float", qualifier: "in" },
            { name: "dotTV", type: "float", qualifier: "in" },
            { name: "dotBV", type: "float", qualifier: "in" },
            { name: "dotTL", type: "float", qualifier: "in" },
            { name: "dotBL", type: "float", qualifier: "in" },
            { name: "dotNV", type: "float", qualifier: "in" },
            { name: "dotNL", type: "float", qualifier: "in" }
        ];
    }

    public function compute(alphaT: Float, alphaB: Float, dotTV: Float, dotBV: Float, dotTL: Float, dotBL: Float, dotNV: Float, dotNL: Float): Float {
        var gv = dotNL * (alphaT * dotTV).length() + (alphaB * dotBV).length() + dotNV.length();
        var gl = dotNV * (alphaT * dotTL).length() + (alphaB * dotBL).length() + dotNL.length();
        var v = OperatorNode.div(0.5, gv + gl);
        return v.saturate();
    }
}