package three.shaderlib.cube;

import haxe.macro.Expr;

class CubeShader {
  public static var vertex:String = "
    varying vec3 vWorldDirection;

    #include <common>

    void main() {
      vWorldDirection = transformDirection( position, modelMatrix );

      #include <begin_vertex>
      #include <project_vertex>

      gl_Position.z = gl_Position.w; // set z to camera.far
    }
  ";

  public static var fragment:String = "
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
  ";
}
```
Note that in Haxe, we use the `package` keyword to define the namespace, and `class` to define a class. The `public static var` keywords are used to define public static variables. The shader code is defined as strings, and the `#include` directives are preserved as-is, assuming that they will be processed by a shader preprocessor.

Also, note that Haxe uses a different syntax for multiline strings, using triple quotes `"""` instead of backticks `