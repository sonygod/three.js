package;

import openfl.display.Shader;
import openfl.display.ShaderInput;

class VerticalTiltShiftShader extends Shader {

  public static var name:String = "VerticalTiltShiftShader";

  public var tDiffuse:ShaderInput;
  public var v:Float;
  public var r:Float;

  public function new() {
    super();
    this.tDiffuse = new ShaderInput(ShaderInput.SAMPLER2D, "tDiffuse");
    this.v = 1.0 / 512.0;
    this.r = 0.35;
  }

  override public function getVertexShader():String {
    return """
      varying vec2 vUv;
      void main() {
        vUv = uv;
        gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
      }
    """;
  }

  override public function getFragmentShader():String {
    return """
      uniform sampler2D tDiffuse;
      uniform float v;
      uniform float r;
      varying vec2 vUv;
      void main() {
        vec4 sum = vec4( 0.0 );
        float vv = v * abs( r - vUv.y );
        sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y - 4.0 * vv ) ) * 0.051;
        sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y - 3.0 * vv ) ) * 0.0918;
        sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y - 2.0 * vv ) ) * 0.12245;
        sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y - 1.0 * vv ) ) * 0.1531;
        sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y ) ) * 0.1633;
        sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y + 1.0 * vv ) ) * 0.1531;
        sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y + 2.0 * vv ) ) * 0.12245;
        sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y + 3.0 * vv ) ) * 0.0918;
        sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y + 4.0 * vv ) ) * 0.051;
        gl_FragColor = sum;
      }
    """;
  }
}


**Explanation:**

1. **Import Necessary Classes:**
   - `openfl.display.Shader`: Represents a shader object.
   - `openfl.display.ShaderInput`: Represents an input to a shader.

2. **Class Definition:**
   - `class VerticalTiltShiftShader extends Shader`: Defines a class named `VerticalTiltShiftShader` that inherits from `Shader`.

3. **Static Variable:**
   - `public static var name:String = "VerticalTiltShiftShader";`: Defines a static variable `name` to store the shader's name.

4. **Shader Input Variables:**
   - `public var tDiffuse:ShaderInput;`: Defines a `ShaderInput` variable `tDiffuse` to represent the input texture.
   - `public var v:Float;`: Defines a `Float` variable `v` to represent the inverse of the height.
   - `public var r:Float;`: Defines a `Float` variable `r` to control the focus position.

5. **Constructor:**
   - `public function new() { super(); ... }`: The constructor initializes the shader.
     - `super()`: Calls the parent constructor.
     - `this.tDiffuse = new ShaderInput(ShaderInput.SAMPLER2D, "tDiffuse");`: Creates a new `ShaderInput` for the texture with type `SAMPLER2D` and name "tDiffuse".
     - `this.v = 1.0 / 512.0;`: Sets the initial value of `v` to 1.0 / 512.0.
     - `this.r = 0.35;`: Sets the initial value of `r` to 0.35.

6. **Vertex Shader:**
   - `override public function getVertexShader():String { ... }`: Overrides the `getVertexShader` method to return the vertex shader code as a string. The code is identical to the JavaScript version.

7. **Fragment Shader:**
   - `override public function getFragmentShader():String { ... }`: Overrides the `getFragmentShader` method to return the fragment shader code as a string. The code is identical to the JavaScript version, with the following changes:
     - The `glsl` tag is removed, as Haxe automatically handles the GLSL language.
     - The `texture2D` function is used instead of `texture`.

**Usage:**


var shader:VerticalTiltShiftShader = new VerticalTiltShiftShader();
// Set the input texture
shader.tDiffuse.value = yourTexture;
// Create a shader material
var material:ShaderMaterial = new ShaderMaterial(shader);
// Apply the material to a display object
yourDisplayObject.material = material;