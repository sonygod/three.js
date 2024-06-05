import NormalNode from "../../accessors/NormalNode";
import PositionNode from "../../accessors/PositionNode";
import PropertyNode from "../../core/PropertyNode";
import ShaderNode from "../../shadernode/ShaderNode";

// https://github.com/google/filament/blob/master/shaders/src/brdf.fs
class D_Charlie extends ShaderNode.TsFn<D_Charlie> {
  public static readonly layout = {
    name: "D_Charlie",
    type: "float",
    inputs: [
      { name: "roughness", type: "float" },
      { name: "dotNH", type: "float" },
    ],
  };

  public static get(roughness: ShaderNode.Float, dotNH: ShaderNode.Float) {
    return new D_Charlie(roughness, dotNH);
  }

  constructor(roughness: ShaderNode.Float, dotNH: ShaderNode.Float) {
    super(D_Charlie.layout, roughness, dotNH);
  }

  public eval() {
    let alpha = this.inputs[0].eval().pow2();

    // Estevez and Kulla 2017, "Production Friendly Microfacet Sheen BRDF"
    let invAlpha = new ShaderNode.Float(1.0).div(alpha);
    let cos2h = this.inputs[1].eval().pow2();
    let sin2h = cos2h.oneMinus().max(new ShaderNode.Float(0.0078125)); // 2^(-14/2), so sin2h^2 > 0 in fp16

    return new ShaderNode.Float(2.0).add(invAlpha).mul(sin2h.pow(invAlpha.mul(new ShaderNode.Float(0.5)))).div(new ShaderNode.Float(2.0 * Math.PI));
  }
}

// https://github.com/google/filament/blob/master/shaders/src/brdf.fs
class V_Neubelt extends ShaderNode.TsFn<V_Neubelt> {
  public static readonly layout = {
    name: "V_Neubelt",
    type: "float",
    inputs: [
      { name: "dotNV", type: "float" },
      { name: "dotNL", type: "float" },
    ],
  };

  public static get(dotNV: ShaderNode.Float, dotNL: ShaderNode.Float) {
    return new V_Neubelt(dotNV, dotNL);
  }

  constructor(dotNV: ShaderNode.Float, dotNL: ShaderNode.Float) {
    super(V_Neubelt.layout, dotNV, dotNL);
  }

  public eval() {
    // Neubelt and Pettineo 2013, "Crafting a Next-gen Material Pipeline for The Order: 1886"
    return new ShaderNode.Float(1.0).div(new ShaderNode.Float(4.0).mul(this.inputs[1].eval().add(this.inputs[0].eval()).sub(this.inputs[1].eval().mul(this.inputs[0].eval()))));
  }
}

class BRDF_Sheen extends ShaderNode.TsFn<BRDF_Sheen> {
  public static readonly layout = {
    name: "BRDF_Sheen",
    type: "float",
    inputs: [],
  };

  public static get(lightDirection: ShaderNode.Vec3) {
    return new BRDF_Sheen(lightDirection);
  }

  constructor(lightDirection: ShaderNode.Vec3) {
    super(BRDF_Sheen.layout, lightDirection);
  }

  public eval() {
    let halfDir = this.inputs[0].eval().add(PositionNode.positionViewDirection).normalize();

    let dotNL = NormalNode.transformedNormalView.dot(this.inputs[0].eval()).clamp();
    let dotNV = NormalNode.transformedNormalView.dot(PositionNode.positionViewDirection).clamp();
    let dotNH = NormalNode.transformedNormalView.dot(halfDir).clamp();

    let D = D_Charlie.get(PropertyNode.sheenRoughness, dotNH);
    let V = V_Neubelt.get(dotNV, dotNL);

    return PropertyNode.sheen.mul(D).mul(V);
  }
}

export default BRDF_Sheen;