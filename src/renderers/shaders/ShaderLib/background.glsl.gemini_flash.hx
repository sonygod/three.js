import openfl.display.Shader;
import openfl.display.ShaderInput;

class GlslShader extends Shader {
  public static function vertex():ShaderInput {
    return new ShaderInput(
      "varying vec2 vUv;\n" +
      "uniform mat3 uvTransform;\n" +
      "\n" +
      "void main() {\n" +
      "\n" +
      "	vUv = ( uvTransform * vec3( uv, 1 ) ).xy;\n" +
      "\n" +
      "	gl_Position = vec4( position.xy, 1.0, 1.0 );\n" +
      "\n" +
      "}"
    );
  }

  public static function fragment():ShaderInput {
    return new ShaderInput(
      "uniform sampler2D t2D;\n" +
      "uniform float backgroundIntensity;\n" +
      "\n" +
      "varying vec2 vUv;\n" +
      "\n" +
      "void main() {\n" +
      "\n" +
      "	vec4 texColor = texture2D( t2D, vUv );\n" +
      "\n" +
      "	#ifdef DECODE_VIDEO_TEXTURE\n" +
      "\n" +
      "		// use inline sRGB decode until browsers properly support SRGB8_APLHA8 with video textures\n" +
      "\n" +
      "		texColor = vec4( mix( pow( texColor.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), texColor.rgb * 0.0773993808, vec3( lessThanEqual( texColor.rgb, vec3( 0.04045 ) ) ) ), texColor.w );\n" +
      "\n" +
      "	#endif\n" +
      "\n" +
      "	texColor.rgb *= backgroundIntensity;\n" +
      "\n" +
      "	gl_FragColor = texColor;\n" +
      "\n" +
      "	#include <tonemapping_fragment>\n" +
      "	#include <colorspace_fragment>\n" +
      "\n" +
      "}"
    );
  }
}


**Explanation:**

1. **Import necessary classes:** We import `Shader` and `ShaderInput` from the `openfl.display` package to work with Haxe's shader system.
2. **Create a class:** We define a class `GlslShader` to encapsulate our shader logic.
3. **Define `vertex()` and `fragment()` functions:** These functions return `ShaderInput` objects containing the GLSL code.
4. **Use string concatenation:** We use string concatenation to combine the different parts of the GLSL code. This is similar to the template literal approach in JavaScript, but it's more verbose.
5. **Replace `#ifdef` directives:** The `#ifdef` directives in the fragment shader are used for conditional compilation in GLSL. We can't use them directly in Haxe, so we'll need to handle those conditions in our code logic.
6. **Include external shaders:** The lines `#include <tonemapping_fragment>` and `#include <colorspace_fragment>` are meant to include external GLSL shaders. We'll need to find a way to include these files in our Haxe project or modify the code to handle them differently.

**How to use:**

1. **Create a `Shader` object:**


var shader:Shader = new GlslShader();


2. **Set the vertex and fragment shaders:**


shader.vertex = GlslShader.vertex();
shader.fragment = GlslShader.fragment();


3. **Apply the shader to a display object:**


myDisplayObject.shader = shader;