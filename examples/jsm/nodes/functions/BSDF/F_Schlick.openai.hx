package three.js.examples.jsm.nodes.functions.BSDF;

import three.js.shadernode.ShaderNode;

class F_Schlick {
  public static function tslFn(f0:Float, f90:Float, dotVH:Float):Float {
    // Optimized variant (presented by Epic at SIGGRAPH '13)
    var fresnel:Float = dotVH * -5.55473 - 6.98316;
    fresnel = Math.exp2(fresnel * dotVH);
    return f0 * (1 - fresnel) + f90 * fresnel;
  }
}