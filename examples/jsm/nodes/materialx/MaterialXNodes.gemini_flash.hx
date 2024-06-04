import mx_noise.MxNoise;
import mx_hsv.MxHsv;
import mx_transform_color.MxTransformColor;
import Math.MathNode;
import Accessors.UVNode;
import ShaderNode.ShaderNode;

class MxUtils {

  public static function aastep(threshold:ShaderNode, value:ShaderNode):ShaderNode {
    threshold = ShaderNode.float(threshold);
    value = ShaderNode.float(value);

    var afwidth = ShaderNode.vec2(value.dFdx(), value.dFdy()).length().mul(0.70710678118654757);

    return MathNode.smoothstep(threshold.sub(afwidth), threshold.add(afwidth), value);
  }

  public static function ramplr(valuel:ShaderNode, valuer:ShaderNode, texcoord:ShaderNode = UVNode.uv()):ShaderNode {
    return _ramp(valuel, valuer, texcoord, "x");
  }

  public static function ramptb(valuet:ShaderNode, valueb:ShaderNode, texcoord:ShaderNode = UVNode.uv()):ShaderNode {
    return _ramp(valuet, valueb, texcoord, "y");
  }

  public static function splitlr(valuel:ShaderNode, valuer:ShaderNode, center:ShaderNode, texcoord:ShaderNode = UVNode.uv()):ShaderNode {
    return _split(valuel, valuer, center, texcoord, "x");
  }

  public static function splittb(valuet:ShaderNode, valueb:ShaderNode, center:ShaderNode, texcoord:ShaderNode = UVNode.uv()):ShaderNode {
    return _split(valuet, valueb, center, texcoord, "y");
  }

  public static function transformUv(uvScale:ShaderNode = 1, uvOffset:ShaderNode = 0, uvGeo:ShaderNode = UVNode.uv()):ShaderNode {
    return uvGeo.mul(uvScale).add(uvOffset);
  }

  public static function safepower(in1:ShaderNode, in2:ShaderNode = 1):ShaderNode {
    in1 = ShaderNode.float(in1);

    return in1.abs().pow(in2).mul(in1.sign());
  }

  public static function contrast(input:ShaderNode, amount:ShaderNode = 1, pivot:ShaderNode = 0.5):ShaderNode {
    return ShaderNode.float(input).sub(pivot).mul(amount).add(pivot);
  }

  public static function noiseFloat(texcoord:ShaderNode = UVNode.uv(), amplitude:ShaderNode = 1, pivot:ShaderNode = 0):ShaderNode {
    return MxNoise.perlinNoiseFloat(texcoord.convert("vec2|vec3")).mul(amplitude).add(pivot);
  }

  // public static function noiseVec2(texcoord:ShaderNode = UVNode.uv(), amplitude:ShaderNode = 1, pivot:ShaderNode = 0):ShaderNode {
  //   return MxNoise.perlinNoiseVec3(texcoord.convert("vec2|vec3")).mul(amplitude).add(pivot);
  // }

  public static function noiseVec3(texcoord:ShaderNode = UVNode.uv(), amplitude:ShaderNode = 1, pivot:ShaderNode = 0):ShaderNode {
    return MxNoise.perlinNoiseVec3(texcoord.convert("vec2|vec3")).mul(amplitude).add(pivot);
  }

  public static function noiseVec4(texcoord:ShaderNode = UVNode.uv(), amplitude:ShaderNode = 1, pivot:ShaderNode = 0):ShaderNode {
    texcoord = texcoord.convert("vec2|vec3");

    var noiseVec4 = ShaderNode.vec4(MxNoise.perlinNoiseVec3(texcoord), MxNoise.perlinNoiseFloat(texcoord.add(ShaderNode.vec2(19, 73))));

    return noiseVec4.mul(amplitude).add(pivot);
  }

  public static function worleyNoiseFloat(texcoord:ShaderNode = UVNode.uv(), jitter:ShaderNode = 1):ShaderNode {
    return MxNoise.worleyNoiseFloat(texcoord.convert("vec2|vec3"), jitter, ShaderNode.int(1));
  }

  public static function worleyNoiseVec2(texcoord:ShaderNode = UVNode.uv(), jitter:ShaderNode = 1):ShaderNode {
    return MxNoise.worleyNoiseVec2(texcoord.convert("vec2|vec3"), jitter, ShaderNode.int(1));
  }

  public static function worleyNoiseVec3(texcoord:ShaderNode = UVNode.uv(), jitter:ShaderNode = 1):ShaderNode {
    return MxNoise.worleyNoiseVec3(texcoord.convert("vec2|vec3"), jitter, ShaderNode.int(1));
  }

  public static function cellNoiseFloat(texcoord:ShaderNode = UVNode.uv()):ShaderNode {
    return MxNoise.cellNoiseFloat(texcoord.convert("vec2|vec3"));
  }

  public static function fractalNoiseFloat(position:ShaderNode = UVNode.uv(), octaves:ShaderNode = 3, lacunarity:ShaderNode = 2, diminish:ShaderNode = 0.5, amplitude:ShaderNode = 1):ShaderNode {
    return MxNoise.fractalNoiseFloat(position, ShaderNode.int(octaves), lacunarity, diminish).mul(amplitude);
  }

  public static function fractalNoiseVec2(position:ShaderNode = UVNode.uv(), octaves:ShaderNode = 3, lacunarity:ShaderNode = 2, diminish:ShaderNode = 0.5, amplitude:ShaderNode = 1):ShaderNode {
    return MxNoise.fractalNoiseVec2(position, ShaderNode.int(octaves), lacunarity, diminish).mul(amplitude);
  }

  public static function fractalNoiseVec3(position:ShaderNode = UVNode.uv(), octaves:ShaderNode = 3, lacunarity:ShaderNode = 2, diminish:ShaderNode = 0.5, amplitude:ShaderNode = 1):ShaderNode {
    return MxNoise.fractalNoiseVec3(position, ShaderNode.int(octaves), lacunarity, diminish).mul(amplitude);
  }

  public static function fractalNoiseVec4(position:ShaderNode = UVNode.uv(), octaves:ShaderNode = 3, lacunarity:ShaderNode = 2, diminish:ShaderNode = 0.5, amplitude:ShaderNode = 1):ShaderNode {
    return MxNoise.fractalNoiseVec4(position, ShaderNode.int(octaves), lacunarity, diminish).mul(amplitude);
  }

  static function _ramp(a:ShaderNode, b:ShaderNode, uv:ShaderNode, p:String):ShaderNode {
    return MathNode.mix(a, b, uv[p].clamp());
  }

  static function _split(a:ShaderNode, b:ShaderNode, center:ShaderNode, uv:ShaderNode, p:String):ShaderNode {
    return MathNode.mix(a, b, MxUtils.aastep(center, uv[p]));
  }
}

public var mx_hsvtorgb:ShaderNode->ShaderNode = MxHsv.hsvtorgb;
public var mx_rgbtohsv:ShaderNode->ShaderNode = MxHsv.rgbtohsv;
public var mx_srgb_texture_to_lin_rec709:ShaderNode->ShaderNode = MxTransformColor.srgbTextureToLinRec709;