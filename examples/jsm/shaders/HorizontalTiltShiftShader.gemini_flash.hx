import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display3D.textures.TextureBase;
import openfl.geom.Matrix;

class HorizontalTiltShiftShader extends Shader {
  public static var name:String = "HorizontalTiltShiftShader";

  public var tDiffuse:ShaderInput = null;
  public var h:ShaderInput = new ShaderInput(1.0 / 512.0);
  public var r:ShaderInput = new ShaderInput(0.35);

  public function new() {
    super();

    this.vertexShader =
    `
    varying vec2 vUv;

    void main() {

      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

    }
    `;

    this.fragmentShader =
    `
    uniform sampler2D tDiffuse;
    uniform float h;
    uniform float r;

    varying vec2 vUv;

    void main() {

      vec4 sum = vec4( 0.0 );

      float hh = h * abs( r - vUv.y );

      sum += texture2D( tDiffuse, vec2( vUv.x - 4.0 * hh, vUv.y ) ) * 0.051;
      sum += texture2D( tDiffuse, vec2( vUv.x - 3.0 * hh, vUv.y ) ) * 0.0918;
      sum += texture2D( tDiffuse, vec2( vUv.x - 2.0 * hh, vUv.y ) ) * 0.12245;
      sum += texture2D( tDiffuse, vec2( vUv.x - 1.0 * hh, vUv.y ) ) * 0.1531;
      sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y ) ) * 0.1633;
      sum += texture2D( tDiffuse, vec2( vUv.x + 1.0 * hh, vUv.y ) ) * 0.1531;
      sum += texture2D( tDiffuse, vec2( vUv.x + 2.0 * hh, vUv.y ) ) * 0.12245;
      sum += texture2D( tDiffuse, vec2( vUv.x + 3.0 * hh, vUv.y ) ) * 0.0918;
      sum += texture2D( tDiffuse, vec2( vUv.x + 4.0 * hh, vUv.y ) ) * 0.051;

      gl_FragColor = sum;

    }
    `;
  }

  public function setTexture(texture:TextureBase):Void {
    this.tDiffuse = new ShaderInput(texture);
  }

  public function setH(value:Float):Void {
    this.h.value = value;
  }

  public function setR(value:Float):Void {
    this.r.value = value;
  }
}


**Explanation:**

* **Shader Class:**  The code defines a class `HorizontalTiltShiftShader` that extends `openfl.display.Shader`.
* **Shader Inputs:** It declares three `ShaderInput` members:
    * `tDiffuse`:  This will hold the input texture.
    * `h`: Represents the horizontal scale factor, initialized to `1.0 / 512.0`.
    * `r`: Controls the position of the "focused" horizontal line, initialized to `0.35`.
* **Constructor:** The constructor sets up the vertex and fragment shaders. The shaders are defined as multiline strings (`""" ... """`). 
* **`setTexture` Method:**  This method takes a `TextureBase` and creates a `ShaderInput` for it, making it available to the shader.
* **`setH` and `setR` Methods:** These methods allow you to modify the `h` and `r` values after the shader is created.

**How to Use:**

1. **Create an instance:** 
   
   var tiltShiftShader = new HorizontalTiltShiftShader();
   

2. **Set the input texture:**
   
   tiltShiftShader.setTexture(myTexture); // Replace 'myTexture' with your actual texture
   

3. **Set optional parameters:**
   
   tiltShiftShader.setH(1.0 / width); // Adjust 'width' based on your texture's width
   tiltShiftShader.setR(0.5); // Adjust 'r' to move the focus line
   

4. **Apply the shader:**
   
   mySprite.shader = tiltShiftShader;