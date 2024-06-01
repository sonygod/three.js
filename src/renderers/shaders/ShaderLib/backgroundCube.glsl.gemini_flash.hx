import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

class Glsl {

  public static function vertex( ctx : Context ) : Expr {
    return macro(
      """
      varying vec3 vWorldDirection;

      #include <common>

      void main() {

        vWorldDirection = transformDirection( position, modelMatrix );

        #include <begin_vertex>
        #include <project_vertex>

        gl_Position.z = gl_Position.w; // set z to camera.far

      }
      """
    );
  }

  public static function fragment( ctx : Context ) : Expr {
    return macro(
      """
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
      """
    );
  }
}


**Explanation:**

1. **Haxe Macros:** We use Haxe macros to generate the GLSL code at compile time. Macros allow us to manipulate the code before it's compiled into the final output.
2. **`Glsl` Class:** The `Glsl` class contains two static functions, `vertex` and `fragment`, which represent the vertex and fragment shaders respectively.
3. **`macro` Function:** Inside the functions, we use the `macro` function to embed the GLSL code. This function takes a string containing the GLSL code and returns an `Expr` object that represents the code.
4. **GLSL Code:** The GLSL code itself is directly embedded within the `macro` function as a string. This keeps the code readable and manageable within the Haxe codebase.
5. **`#include` Directives:** The `#include` directives are used to include common GLSL snippets. These snippets are likely defined in separate files and are used to reduce code repetition and improve organization.

**Usage:**

To use these functions, you would call them within your Haxe code, like this:


// Accessing the vertex shader
var vertexShader = Glsl.vertex( Context.current );

// Accessing the fragment shader
var fragmentShader = Glsl.fragment( Context.current );