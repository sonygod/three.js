import three.js.examples.jsm.math.OperatorNode;
import three.js.examples.jsm.math.MathNode;
import three.js.examples.jsm.shadernode.ShaderNode;

// Moving Frostbite to Physically Based Rendering 3.0 - page 12, listing 2
// https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
var V_GGX_SmithCorrelated = ShaderNode.tslFn(function(data) {
    var alpha = data.alpha;
    var dotNL = data.dotNL;
    var dotNV = data.dotNV;

    var a2 = alpha.pow2();

    var gv = dotNL.mul(a2.add(a2.oneMinus().mul(dotNV.pow2())).sqrt());
    var gl = dotNV.mul(a2.add(a2.oneMinus().mul(dotNL.pow2())).sqrt());

    return OperatorNode.div(0.5, gv.add(gl).max(MathNode.EPSILON));
}).setLayout({
    name: 'V_GGX_SmithCorrelated',
    type: 'float',
    inputs: [
        { name: 'alpha', type: 'float' },
        { name: 'dotNL', type: 'float' },
        { name: 'dotNV', type: 'float' }
    ]
});

export default V_GGX_SmithCorrelated;