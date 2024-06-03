import haxe.macro.Expr;
import haxe.macro.Context;

class Glsl {
  static macro(code:Expr, context:Context) {
    return macro {
      // Remove the /* glsl */ comment
      var strCode = code.toString().replace(/\/\* glsl \*\//g, "");
      // Wrap the code in a string literal
      return Expr.stringLiteral(strCode);
    };
  }
}

@:glsl
var vertex = `
varying vec3 vWorldDirection;

#include <common>

void main() {

	vWorldDirection = transformDirection( position, modelMatrix );

	#include <begin_vertex>
	#include <project_vertex>

}
`;

@:glsl
var fragment = `
uniform sampler2D tEquirect;

varying vec3 vWorldDirection;

#include <common>

void main() {

	vec3 direction = normalize( vWorldDirection );

	vec2 sampleUV = equirectUv( direction );

	gl_FragColor = texture2D( tEquirect, sampleUV );

	#include <tonemapping_fragment>
	#include <colorspace_fragment>

}
`;


**Explanation:**

1. **`@:glsl` macro**: This macro uses the `haxe.macro.Expr` and `haxe.macro.Context` classes to process the GLSL code. It removes the `/* glsl */` comment and wraps the code in a string literal.
2. **String Literals**: The `@:glsl` macro ensures that the GLSL code is treated as a string literal, avoiding syntax errors.
3. **`#include` Directives**: The `#include` directives are assumed to be handled by the Haxe library or framework you are using. You'll need to make sure these directives are properly resolved during compilation.

**Using the Code:**

This code defines two variables, `vertex` and `fragment`, which contain the GLSL code for a vertex shader and a fragment shader. You can then use these variables with your Haxe library or framework to create a shader program.

**Example with Three.js:**


import three.core.Object3D;
import three.materials.ShaderMaterial;
import three.textures.Texture;

class MyShader extends Object3D {
  public function new() {
    super();

    var texture = new Texture();
    texture.image.src = "path/to/equirectangular.png";
    texture.needsUpdate = true;

    var material = new ShaderMaterial({
      uniforms: {
        tEquirect: { value: texture }
      },
      vertexShader: vertex,
      fragmentShader: fragment
    });

    this.add(new Object3D(material));
  }
}