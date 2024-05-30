package three.js.examples.jsm.nodes.materialx.lib;

import three.js.shadernode.ShaderNode;
import three.js.math.OperatorNode;
import three.js.math.MathNode;

class MxTransformColor {
  static public function mx_srgb_texture_to_lin_rec709(color_immutable:Vec3):Vec3 {
    var color = new Vec3(color_immutable);
    var isAbove = new BVec3(new OperatorNode(GreaterThan, color, new Vec3(0.04045)));
    var linSeg = new Vec3(color.div(12.92));
    var powSeg = new Vec3(Math.pow(max(color.add(new Vec3(0.055)), new Vec3(0.0)).div(1.055), new Vec3(2.4)));
    return new Vec3(MathNode.mix(linSeg, powSeg, isAbove));
  }

  public static function setLayout() {
    mx_srgb_texture_to_lin_rec709.setLayout({
      name: 'mx_srgb_texture_to_lin_rec709',
      type: 'vec3',
      inputs: [
        { name: 'color', type: 'vec3' }
      ]
    });
  }
}