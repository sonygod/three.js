import MathNode.EPSILON;
import OperatorNode.div;
import ShaderNode.tslFn;

class V_GGX_SmithCorrelated {
    public static function new() {
        return tslFn((params) => {
            var alpha = params.alpha;
            var dotNL = params.dotNL;
            var dotNV = params.dotNV;

            var a2 = alpha * alpha;

            var gv = dotNL * Math.sqrt(a2 + (1 - a2) * dotNV * dotNV);
            var gl = dotNV * Math.sqrt(a2 + (1 - a2) * dotNL * dotNL);

            return div(0.5, Math.max(gv + gl, EPSILON));
        }).setLayout({
            name: 'V_GGX_SmithCorrelated',
            type: 'Float',
            inputs: [
                { name: 'alpha', type: 'Float' },
                { name: 'dotNL', type: 'Float' },
                { name: 'dotNV', type: 'Float' }
            ]
        });
    }
}