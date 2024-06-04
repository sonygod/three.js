import shader.ShaderNode;
import shader.vec3;

class Schlick_to_F0 extends ShaderNode {
  static function new() {
    return new Schlick_to_F0();
  }

  override function get(f: vec3, f90: Float, dotVH: Float): vec3 {
    var x = dotVH.oneMinus().saturate();
    var x2 = x.mul(x);
    var x5 = x.mul(x2, x2).clamp(0, 0.9999);

    return f.sub(vec3(f90).mul(x5)).div(x5.oneMinus());
  }

  override function layout() {
    return {
      name: "Schlick_to_F0",
      type: "vec3",
      inputs: [
        { name: "f", type: "vec3" },
        { name: "f90", type: "float" },
        { name: "dotVH", type: "float" }
      ]
    };
  }
}

export default Schlick_to_F0;