package three.js.examples.jvm.nodes.functions.BSDF;

import three.js.shadernode.ShaderNode;

class D_GGX {
  public static function tslFn(alpha: Float, dotNH: Float): Float {
    var a2: Float = alpha * alpha;
    var denom: Float = dotNH * dotNH * (1 - a2);
    return a2 / (denom * denom) * 1.0 / Math.PI;
  }

  public static function getD_GGX(): ShaderNode {
    return ShaderNode.createFromTSLEquation({
      name: 'D_GGX',
      type: 'float',
      inputs: [
        { name: 'alpha', type: 'float' },
        { name: 'dotNH', type: 'float' }
      ],
      equation: tslFn
    });
  }
}