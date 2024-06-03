import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ComplexType;
import haxe.macro.ExprOf;

class Glsl {

  public static function vertex(c:Context):Expr {
    return macro {
      var vertex = """
varying vec2 vUv;
uniform mat3 uvTransform;

void main() {

	vUv = ( uvTransform * vec3( uv, 1 ) ).xy;

	gl_Position = vec4( position.xy, 1.0, 1.0 );

}
""";
      return vertex;
    };
  }

  public static function fragment(c:Context):Expr {
    return macro {
      var fragment = """
uniform sampler2D t2D;
uniform float backgroundIntensity;

varying vec2 vUv;

void main() {

	vec4 texColor = texture2D( t2D, vUv );

	#ifdef DECODE_VIDEO_TEXTURE

		// use inline sRGB decode until browsers properly support SRGB8_APLHA8 with video textures

		texColor = vec4( mix( pow( texColor.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), texColor.rgb * 0.0773993808, vec3( lessThanEqual( texColor.rgb, vec3( 0.04045 ) ) ) ), texColor.w );

	#endif

	texColor.rgb *= backgroundIntensity;

	gl_FragColor = texColor;

	#include <tonemapping_fragment>
	#include <colorspace_fragment>

}
""";
      return fragment;
    };
  }

}


This code does the following:

1. **Defines a Glsl class:** This class acts as a container for the shader code.
2. **Uses macros for `vertex` and `fragment` functions:** The `macro` keyword allows us to embed the GLSL code directly into the Haxe code.
3. **Uses `"""` for multi-line strings:** This allows us to write the GLSL code as a multi-line string within the macro.

To use this code, you can import it into your Haxe project and then access the `vertex` and `fragment` functions. For example:


import Glsl;

class MyShader {

  public static function main() {
    var vertexShader = Glsl.vertex();
    var fragmentShader = Glsl.fragment();
    // ... use the shader code here ...
  }
}