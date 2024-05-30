package three.js.examples.jsm.nodes.functions.BSDF;

import math.OperatorNode;
import math.MathNode;
import shaders.ShaderNode;

// Moving Frostbite to Physically Based Rendering 3.0 - page 12, listing 2
// https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
class V_GGX_SmithCorrelated {
    public static function tslFn alphaDotNLDotNV ( alpha:Float, dotNL:Float, dotNV:Float ):Float {
        var a2:Float = alpha * alpha;
        var gv:Float = dotNL * Math.sqrt(a2 + (1 - a2) * dotNV * dotNV);
        var gl:Float = dotNV * Math.sqrt(a2 + (1 - a2) * dotNL * dotNL);
        return 0.5 / (gv + gl + MathNode.EPSILON);
    }

    public static function setLayout() {
        ShaderNode.layout = {
            name: 'V_GGX_SmithCorrelated',
            type: 'float',
            inputs: [
                { name: 'alpha', type: 'float' },
                { name: 'dotNL', type: 'float' },
                { name: 'dotNV', type: 'float' }
            ]
        };
    }
}

export default V_GGX_SmithCorrelated;