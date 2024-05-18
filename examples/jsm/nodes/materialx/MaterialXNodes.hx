package three.js.examples.jsm.nodes.materialx;

import hxsl.ShaderNode;
import hxsl.Nodes.*;

class MaterialXNodes {
  static public function mx_aastep(threshold:Float, value:Float):Float {
    var afwidth = vec2(value.dFdx(), value.dFdy()).length() * 0.70710678118654757;
    return smoothstep(threshold - afwidth, threshold + afwidth, value);
  }

  static public function _ramp(a:Float, b:Float, uv:Vec2, p:String):Float {
    return mix(a, b, uv.get(p).clamp());
  }

  static public function mx_ramplr(valuel:Float, valuer:Float, ?texcoord:Vec2):Float {
    return _ramp(valuel, valuer, texcoord != null ? texcoord : uv(), 'x');
  }

  static public function mx_ramptb(valuet:Float, valueb:Float, ?texcoord:Vec2):Float {
    return _ramp(valuet, valueb, texcoord != null ? texcoord : uv(), 'y');
  }

  static public function _split(a:Float, b:Float, center:Float, uv:Vec2, p:String):Float {
    return mix(a, b, mx_aastep(center, uv.get(p)));
  }

  static public function mx_splitlr(valuel:Float, valuer:Float, center:Float, ?texcoord:Vec2):Float {
    return _split(valuel, valuer, center, texcoord != null ? texcoord : uv(), 'x');
  }

  static public function mx_splittb(valuet:Float, valueb:Float, center:Float, ?texcoord:Vec2):Float {
    return _split(valuet, valueb, center, texcoord != null ? texcoord : uv(), 'y');
  }

  static public function mx_transform_uv(?uv_scale:Float = 1, ?uv_offset:Float = 0, ?uv_geo:Vec2 = uv()):Vec2 {
    return uv_geo.mul(uv_scale).add(uv_offset);
  }

  static public function mx_safepower(in1:Float, ?in2:Float = 1):Float {
    return Math.pow(Math.abs(in1), in2) * (in1 < 0 ? -1 : 1);
  }

  static public function mx_contrast(input:Float, ?amount:Float = 1, ?pivot:Float = .5):Float {
    return (input - pivot) * amount + pivot;
  }

  static public function mx_noise_float(?texcoord:Vec2 = uv(), ?amplitude:Float = 1, ?pivot:Float = 0):Float {
    return mx_perlin_noise_float(texcoord != null ? texcoord : uv()).mul(amplitude).add(pivot);
  }

  // static public function mx_noise_vec2(?texcoord:Vec2 = uv(), ?amplitude:Float = 1, ?pivot:Float = 0):Vec2 {
  //   return mx_perlin_noise_vec3(texcoord != null ? texcoord : uv()).mul(amplitude).add(pivot);
  // }

  static public function mx_noise_vec3(?texcoord:Vec2 = uv(), ?amplitude:Float = 1, ?pivot:Float = 0):Vec3 {
    return mx_perlin_noise_vec3(texcoord != null ? texcoord : uv()).mul(amplitude).add(pivot);
  }

  static public function mx_noise_vec4(?texcoord:Vec2 = uv(), ?amplitude:Float = 1, ?pivot:Float = 0):Vec4 {
    texcoord = texcoord != null ? texcoord : uv();
    var noise_vec4 = new Vec4(mx_perlin_noise_vec3(texcoord), mx_perlin_noise_float(texcoord.add(new Vec2(19, 73))));
    return noise_vec4.mul(amplitude).add(pivot);
  }

  static public function mx_worley_noise_float(?texcoord:Vec2 = uv(), ?jitter:Float = 1):Float {
    return worley_noise_float(texcoord != null ? texcoord : uv(), jitter, 1);
  }

  static public function mx_worley_noise_vec2(?texcoord:Vec2 = uv(), ?jitter:Float = 1):Vec2 {
    return worley_noise_vec2(texcoord != null ? texcoord : uv(), jitter, 1);
  }

  static public function mx_worley_noise_vec3(?texcoord:Vec2 = uv(), ?jitter:Float = 1):Vec3 {
    return worley_noise_vec3(texcoord != null ? texcoord : uv(), jitter, 1);
  }

  static public function mx_cell_noise_float(?texcoord:Vec2 = uv()):Float {
    return cell_noise_float(texcoord != null ? texcoord : uv());
  }

  static public function mx_fractal_noise_float(?position:Vec2 = uv(), ?octaves:Int = 3, ?lacunarity:Float = 2, ?diminish:Float = .5, ?amplitude:Float = 1):Float {
    return fractal_noise_float(position != null ? position : uv(), octaves, lacunarity, diminish).mul(amplitude);
  }

  static public function mx_fractal_noise_vec2(?position:Vec2 = uv(), ?octaves:Int = 3, ?lacunarity:Float = 2, ?diminish:Float = .5, ?amplitude:Float = 1):Vec2 {
    return fractal_noise_vec2(position != null ? position : uv(), octaves, lacunarity, diminish).mul(amplitude);
  }

  static public function mx_fractal_noise_vec3(?position:Vec2 = uv(), ?octaves:Int = 3, ?lacunarity:Float = 2, ?diminish:Float = .5, ?amplitude:Float = 1):Vec3 {
    return fractal_noise_vec3(position != null ? position : uv(), octaves, lacunarity, diminish).mul(amplitude);
  }

  static public function mx_fractal_noise_vec4(?position:Vec2 = uv(), ?octaves:Int = 3, ?lacunarity:Float = 2, ?diminish:Float = .5, ?amplitude:Float = 1):Vec4 {
    return fractal_noise_vec4(position != null ? position : uv(), octaves, lacunarity, diminish).mul(amplitude);
  }
}