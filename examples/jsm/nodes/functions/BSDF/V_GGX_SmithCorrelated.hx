package three.js.examples.jsm.nodes.functions.BSDF;

import math.OperatorNode;
import math.MathNode;
import shadernode.ShaderNode;

class V_GGX_SmithCorrelated {
  public static function tslFn(alpha:Float, dotNL:Float, dotNV:Float):Float {
    var a2:Float = alpha * alpha;
    var gv:Float = dotNL * Math.sqrt(a2 + (1 - a2) * dotNV * dotNV);
    var gl:Float = dotNV * Math.sqrt(a2 + (1 - a2) * dotNL * dotNL);
    return 0.5 / (gv + gl + MathNode.EPSILON);
  }

  public static function main() {
    var node = new ShaderNode(tslFn, {
      name: 'V_GGX_SmithCorrelated',
      type: 'float',
      inputs: [
        { name: 'alpha', type: 'float' },
        { name: 'dotNL', type: 'float' },
        { name: 'dotNV', type: 'float' }
      ]
    });
    return node;
  }
}