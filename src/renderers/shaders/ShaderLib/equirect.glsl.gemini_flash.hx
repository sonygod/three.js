import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Code;
import haxe.macro.Tools;

class Glsl {

  public static function vertex(context:Context):Expr {
    return macro(
      Code.expression(
        "hlsl.Shader.createVertex(function(v){ " +
        "v.vWorldDirection = hlsl.Math.transformDirection(v.position, v.modelMatrix);" +
        "hlsl.Shader.beginVertex(v);" +
        "hlsl.Shader.projectVertex(v);" +
        "})"
      )
    );
  }

  public static function fragment(context:Context):Expr {
    return macro(
      Code.expression(
        "hlsl.Shader.createFragment(function(v){ " +
        "var direction = hlsl.Math.normalize(v.vWorldDirection);" +
        "var sampleUV = hlsl.Math.equirectUv(direction);" +
        "v.glFragColor = hlsl.Texture.sample2D(v.tEquirect, sampleUV);" +
        "hlsl.Shader.tonemappingFragment(v);" +
        "hlsl.Shader.colorSpaceFragment(v);" +
        "})"
      )
    );
  }

}

// Usage example:
class MyShader {
  static var vertex = Glsl.vertex();
  static var fragment = Glsl.fragment();
}