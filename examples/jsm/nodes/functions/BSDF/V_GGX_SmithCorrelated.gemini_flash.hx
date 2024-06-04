import math.OperatorNode;
import math.MathNode;
import shadernode.ShaderNode;

// Moving Frostbite to Physically Based Rendering 3.0 - page 12, listing 2
// https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
class V_GGX_SmithCorrelated extends ShaderNode {
    public function new() {
        super(
            "V_GGX_SmithCorrelated",
            "float",
            [
                {name: "alpha", type: "float"},
                {name: "dotNL", type: "float"},
                {name: "dotNV", type: "float"}
            ]
        );
    }
    
    override public function get(inputs:Map<String,Dynamic>) : Dynamic {
        var alpha = inputs.get("alpha");
        var dotNL = inputs.get("dotNL");
        var dotNV = inputs.get("dotNV");
        
        var a2 = alpha.pow2();
        
        var gv = dotNL.mul(a2.add(a2.oneMinus().mul(dotNV.pow2()))).sqrt();
        var gl = dotNV.mul(a2.add(a2.oneMinus().mul(dotNL.pow2()))).sqrt();
        
        return OperatorNode.div(0.5, gv.add(gl).max(MathNode.EPSILON));
    }
}

export default V_GGX_SmithCorrelated;