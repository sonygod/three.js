import NormalNode from "../../accessors/NormalNode";
import PositionNode from "../../accessors/PositionNode";
import PropertyNode from "../../core/PropertyNode";
import ShaderNode from "../../shadernode/ShaderNode";

// https://github.com/google/filament/blob/master/shaders/src/brdf.fs
class D_Charlie extends ShaderNode.Float {
  public static get(roughness: ShaderNode.Float, dotNH: ShaderNode.Float): D_Charlie {
    return new D_Charlie(roughness, dotNH);
  }

  constructor(roughness: ShaderNode.Float, dotNH: ShaderNode.Float) {
    super();
    this.addInput("roughness", roughness);
    this.addInput("dotNH", dotNH);
  }

  public generateCode(): String {
    var alpha = this.getInput("roughness").pow2();
    var invAlpha = ShaderNode.Float.one.div(alpha);
    var cos2h = this.getInput("dotNH").pow2();
    var sin2h = cos2h.oneMinus().max(ShaderNode.Float.fromFloat(0.0078125)); // 2^(-14/2), so sin2h^2 > 0 in fp16
    return `(${ShaderNode.Float.fromFloat(2.0).add(invAlpha).mul(sin2h.pow(invAlpha.mul(ShaderNode.Float.fromFloat(0.5)))).div(ShaderNode.Float.fromFloat(2.0).mul(Math.PI))})`;
  }
}

// https://github.com/google/filament/blob/master/shaders/src/brdf.fs
class V_Neubelt extends ShaderNode.Float {
  public static get(dotNV: ShaderNode.Float, dotNL: ShaderNode.Float): V_Neubelt {
    return new V_Neubelt(dotNV, dotNL);
  }

  constructor(dotNV: ShaderNode.Float, dotNL: ShaderNode.Float) {
    super();
    this.addInput("dotNV", dotNV);
    this.addInput("dotNL", dotNL);
  }

  public generateCode(): String {
    return `(${ShaderNode.Float.one.div(ShaderNode.Float.fromFloat(4.0).mul(this.getInput("dotNL").add(this.getInput("dotNV")).sub(this.getInput("dotNL").mul(this.getInput("dotNV")))))})`;
  }
}

class BRDF_Sheen extends ShaderNode.Float {
  public static get(lightDirection: ShaderNode.Vec3): BRDF_Sheen {
    return new BRDF_Sheen(lightDirection);
  }

  constructor(lightDirection: ShaderNode.Vec3) {
    super();
    this.addInput("lightDirection", lightDirection);
  }

  public generateCode(): String {
    var halfDir = this.getInput("lightDirection").add(PositionNode.positionViewDirection).normalize();
    var dotNL = NormalNode.transformedNormalView.dot(this.getInput("lightDirection")).clamp();
    var dotNV = NormalNode.transformedNormalView.dot(PositionNode.positionViewDirection).clamp();
    var dotNH = NormalNode.transformedNormalView.dot(halfDir).clamp();
    var D = D_Charlie.get(PropertyNode.sheenRoughness, dotNH);
    var V = V_Neubelt.get(dotNV, dotNL);
    return `(${PropertyNode.sheen.mul(D).mul(V)})`;
  }
}

export default BRDF_Sheen;