import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ExprTools;

class Glsl {

	public static macro vertex(ctx: Context): Expr {
		return macro glsl("void main() {\n\n\tgl_Position = vec4( position, 1.0 );\n\n}");
	}

	public static macro fragment(ctx: Context): Expr {
		return macro glsl(
			"uniform sampler2D shadow_pass;\n" +
			"uniform vec2 resolution;\n" +
			"uniform float radius;\n\n" +
			"#include <packing>\n\n" +
			"void main() {\n\n" +
			"\tconst float samples = float( VSM_SAMPLES );\n\n" +
			"\tfloat mean = 0.0;\n" +
			"\tfloat squared_mean = 0.0;\n\n" +
			"\tfloat uvStride = samples <= 1.0 ? 0.0 : 2.0 / ( samples - 1.0 );\n" +
			"\tfloat uvStart = samples <= 1.0 ? 0.0 : - 1.0;\n" +
			"\tfor ( float i = 0.0; i < samples; i ++ ) {\n\n" +
			"\t\tfloat uvOffset = uvStart + i * uvStride;\n\n" +
			"\t\t#ifdef HORIZONTAL_PASS\n\n" +
			"\t\t\tvec2 distribution = unpackRGBATo2Half( texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( uvOffset, 0.0 ) * radius ) / resolution ) );\n" +
			"\t\t\tmean += distribution.x;\n" +
			"\t\t\tsquared_mean += distribution.y * distribution.y + distribution.x * distribution.x;\n\n" +
			"\t\t#else\n\n" +
			"\t\t\tfloat depth = unpackRGBAToDepth( texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( 0.0, uvOffset ) * radius ) / resolution ) );\n" +
			"\t\t\tmean += depth;\n" +
			"\t\t\tsquared_mean += depth * depth;\n\n" +
			"\t\t#endif\n\n" +
			"\t}\n\n" +
			"\tmean = mean / samples;\n" +
			"\tsquared_mean = squared_mean / samples;\n\n" +
			"\tfloat std_dev = sqrt( squared_mean - mean * mean );\n\n" +
			"\tgl_FragColor = pack2HalfToRGBA( vec2( mean, std_dev ) );\n\n" +
			"}"
		);
	}

	static function macro glsl(glsl: String): Expr {
		return ExprTools.makeString(glsl);
	}
}


**Explanation:**

1. **Glsl Class:** This class contains macro definitions for `vertex` and `fragment` shaders.
2. **`macro` keyword:** It defines the macro function.
3. **`glsl` helper function:** This function takes a string of GLSL code and wraps it in a string literal expression.
4. **Vertex Shader:** The `vertex` macro contains the basic vertex shader code that simply passes the position attribute to `gl_Position`.
5. **Fragment Shader:** The `fragment` macro contains the more complex fragment shader code. It samples the shadow map using VSM (Variance Shadow Mapping) and calculates the mean and standard deviation of the sampled depths. The result is then packed into a `vec2` and stored in `gl_FragColor`.
6. **`#ifdef HORIZONTAL_PASS`:** This directive allows you to choose between horizontal and vertical sampling for VSM depending on the pass you are executing.
7. **`unpackRGBATo2Half` and `unpackRGBAToDepth`:** These are functions provided by the GLSL packing library. They are used to unpack the depth and variance information from the shadow map.
8. **`pack2HalfToRGBA`:** This function packs the mean and standard deviation into a `vec2` and then packs it into a RGBA color for output.

**Usage:**


class MyShader {
	static var vertex = Glsl.vertex();
	static var fragment = Glsl.fragment();
}