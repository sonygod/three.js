import jsm.nodes.shadernode.ShaderNode;
import jsm.nodes.math.MathNode;

class F_Schlick {
  public static function calculate(f0: MathNode, f90: MathNode, dotVH: MathNode): MathNode {
    var fresnel = dotVH.mul(-5.55473).sub(6.98316).mul(dotVH).exp2();
    return f0.mul(fresnel.oneMinus()).add(f90.mul(fresnel));
  }
}