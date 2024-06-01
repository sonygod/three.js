import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ComplexType;
import haxe.macro.Expr.Const;

class Glsl {
    public static function vertex(ctx:Context) {
        return macro {
            var glsl = """
varying vec3 vWorldDirection;

#include <common>

void main() {

	vWorldDirection = transformDirection( position, modelMatrix );

	#include <begin_vertex>
	#include <project_vertex>

	gl_Position.z = gl_Position.w; // set z to camera.far

}
            """;
            return Const(ctx.makeString(glsl));
        };
    }

    public static function fragment(ctx:Context) {
        return macro {
            var glsl = """
uniform samplerCube tCube;
uniform float tFlip;
uniform float opacity;

varying vec3 vWorldDirection;

void main() {

	vec4 texColor = textureCube( tCube, vec3( tFlip * vWorldDirection.x, vWorldDirection.yz ) );

	gl_FragColor = texColor;
	gl_FragColor.a *= opacity;

	#include <tonemapping_fragment>
	#include <colorspace_fragment>

}
            """;
            return Const(ctx.makeString(glsl));
        };
    }
}


**Explanation:**

1. **Imports:** We import necessary macros from `haxe.macro` to work with expressions, types, and contexts.
2. **Glsl Class:** We create a class `Glsl` to encapsulate the GLSL code generation.
3. **`vertex` and `fragment` Functions:**
   - Each function uses the `macro` keyword to define a macro that generates code at compile time.
   - Inside the macro, we use a multiline string (`""" ... """`) to hold the GLSL code.
   - We use `ctx.makeString(glsl)` to convert the GLSL string into a constant expression that can be used in the generated Haxe code.
4. **Const Expression:** The `Const` expression is used to create a constant expression from the generated GLSL string.

**Usage:**

To use the generated GLSL code in your Haxe application, you can simply call the `vertex` and `fragment` functions like this:


var vertexShader = Glsl.vertex();
var fragmentShader = Glsl.fragment();