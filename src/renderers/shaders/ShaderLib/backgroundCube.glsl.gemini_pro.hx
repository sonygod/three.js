import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class GlslMacro {
	static macro function glsl(code:Expr):Expr {
		return macro {
			var result = code.toString().replace(/^\s*\/\* glsl \*\//, "");
			result = result.replace(/^\s*\/\*.*?\*\//gm, "");
			result = result.replace(/^\s*\/\/.*?\n/gm, "");
			return Expr.string(result);
		};
	}
}

class VertexShader {
	public static function main(ctx:Context):Expr {
		return macro {
			var code = GlslMacro.glsl(Expr.string(`
varying vec3 vWorldDirection;

#include <common>

void main() {

	vWorldDirection = transformDirection( position, modelMatrix );

	#include <begin_vertex>
	#include <project_vertex>

	gl_Position.z = gl_Position.w; // set z to camera.far

}
			`));
			return Expr.call(Type.resolve("haxe.macro.Context").get(), "code", [code]);
		};
	}
}

class FragmentShader {
	public static function main(ctx:Context):Expr {
		return macro {
			var code = GlslMacro.glsl(Expr.string(`

#ifdef ENVMAP_TYPE_CUBE

	uniform samplerCube envMap;

#elif defined( ENVMAP_TYPE_CUBE_UV )

	uniform sampler2D envMap;

#endif

uniform float flipEnvMap;
uniform float backgroundBlurriness;
uniform float backgroundIntensity;
uniform mat3 backgroundRotation;

varying vec3 vWorldDirection;

#include <cube_uv_reflection_fragment>

void main() {

	#ifdef ENVMAP_TYPE_CUBE

		vec4 texColor = textureCube( envMap, backgroundRotation * vec3( flipEnvMap * vWorldDirection.x, vWorldDirection.yz ) );

	#elif defined( ENVMAP_TYPE_CUBE_UV )

		vec4 texColor = textureCubeUV( envMap, backgroundRotation * vWorldDirection, backgroundBlurriness );

	#else

		vec4 texColor = vec4( 0.0, 0.0, 0.0, 1.0 );

	#endif

	texColor.rgb *= backgroundIntensity;

	gl_FragColor = texColor;

	#include <tonemapping_fragment>
	#include <colorspace_fragment>

}
			`));
			return Expr.call(Type.resolve("haxe.macro.Context").get(), "code", [code]);
		};
	}
}


**Explanation:**

1. **GlslMacro:**
   - This class defines a macro `glsl` that takes a string expression as input and performs the following:
     - Removes the initial `/* glsl */` comment.
     - Removes all single and multi-line comments.
     - Returns the remaining code as a string expression.
2. **VertexShader and FragmentShader:**
   - These classes define macros for the vertex and fragment shaders, respectively.
   - Each macro:
     - Uses `GlslMacro.glsl` to process the GLSL code.
     - Uses `haxe.macro.Context.code` to embed the processed GLSL code into the Haxe code.

**Usage:**

You can use the macros like this in your Haxe code:


import shaders.VertexShader;
import shaders.FragmentShader;

class MyScene {
	public static function main():Void {
		var vertexShader = VertexShader.main(); // This will contain the GLSL code
		var fragmentShader = FragmentShader.main(); // This will contain the GLSL code
		// ... your shader initialization and rendering code here
	}
}