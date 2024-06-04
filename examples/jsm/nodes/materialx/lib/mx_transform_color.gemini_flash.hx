import shadernode.ShaderNode;
import shadernode.ShaderNode.bvec3;
import shadernode.ShaderNode.vec3;
import shadernode.ShaderNode.tslFn;
import math.OperatorNode.greaterThan;
import math.MathNode.max;
import math.MathNode.pow;
import math.MathNode.mix;

class MxSrgbTextureToLinRec709 extends ShaderNode {
  public static function new(color_immutable: vec3) {
    var color = vec3.fromVar(vec3(color_immutable));
    var isAbove = bvec3.fromVar(bvec3(greaterThan(color, vec3(0.04045))));
    var linSeg = vec3.fromVar(vec3(color.div(12.92)));
    var powSeg = vec3.fromVar(vec3(pow(max(color.add(vec3(0.055)), vec3(0.0)).div(1.055), vec3(2.4))));
    return mix(linSeg, powSeg, isAbove);
  }

  public static function getLayout() {
    return {
      name: "mx_srgb_texture_to_lin_rec709",
      type: "vec3",
      inputs: [
        {name: "color", type: "vec3"}
      ]
    };
  }
}

var mx_srgb_texture_to_lin_rec709 = tslFn(MxSrgbTextureToLinRec709.new);
mx_srgb_texture_to_lin_rec709.setLayout(MxSrgbTextureToLinRec709.getLayout());

class MxSrgbTextureToLinRec709 {
  public static function new(color_immutable: vec3) {
    var color = vec3.fromVar(vec3(color_immutable));
    var isAbove = bvec3.fromVar(bvec3(greaterThan(color, vec3(0.04045))));
    var linSeg = vec3.fromVar(vec3(color.div(12.92)));
    var powSeg = vec3.fromVar(vec3(pow(max(color.add(vec3(0.055)), vec3(0.0)).div(1.055), vec3(2.4))));
    return mix(linSeg, powSeg, isAbove);
  }

  public static function getLayout() {
    return {
      name: "mx_srgb_texture_to_lin_rec709",
      type: "vec3",
      inputs: [
        {name: "color", type: "vec3"}
      ]
    };
  }
}

var mx_srgb_texture_to_lin_rec709 = tslFn(MxSrgbTextureToLinRec709.new);
mx_srgb_texture_to_lin_rec709.setLayout(MxSrgbTextureToLinRec709.getLayout());