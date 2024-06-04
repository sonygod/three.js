import shadernode.ShaderNode;

class F_Schlick extends ShaderNode {
  public static function new(f0:ShaderNode, f90:ShaderNode, dotVH:ShaderNode):F_Schlick {
    return new F_Schlick(f0, f90, dotVH);
  }

  public function new(f0:ShaderNode, f90:ShaderNode, dotVH:ShaderNode) {
    super();
    this.f0 = f0;
    this.f90 = f90;
    this.dotVH = dotVH;
  }

  public var f0:ShaderNode;
  public var f90:ShaderNode;
  public var dotVH:ShaderNode;

  override public function getValue():Dynamic {
    // Optimized variant (presented by Epic at SIGGRAPH '13)
    // https://cdn2.unrealengine.com/Resources/files/2013SiggraphPresentationsNotes-26915738.pdf
    var fresnel = dotVH.mul(-5.55473).sub(6.98316).mul(dotVH).exp2();
    return f0.mul(fresnel.oneMinus()).add(f90.mul(fresnel));
  }
}