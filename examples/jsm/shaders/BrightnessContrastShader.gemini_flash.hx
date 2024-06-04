import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class BrightnessContrastShader extends Shader {

  public static var name:String = "BrightnessContrastShader";

  public static var uniforms:Map<String, ShaderParameter> = new Map<String, ShaderParameter>()
    .set("tDiffuse", new ShaderInput(ShaderInput.SAMPLER2D))
    .set("brightness", new ShaderParameter(ShaderParameter.FLOAT))
    .set("contrast", new ShaderParameter(ShaderParameter.FLOAT));

  public static var vertexShader:String = """
    varying vec2 vUv;

    void main() {

      vUv = uv;

      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

    }
  """;

  public static var fragmentShader:String = """
    uniform sampler2D tDiffuse;
    uniform float brightness;
    uniform float contrast;

    varying vec2 vUv;

    void main() {

      gl_FragColor = texture2D( tDiffuse, vUv );

      gl_FragColor.rgb += brightness;

      if (contrast > 0.0) {
        gl_FragColor.rgb = (gl_FragColor.rgb - 0.5) / (1.0 - contrast) + 0.5;
      } else {
        gl_FragColor.rgb = (gl_FragColor.rgb - 0.5) * (1.0 + contrast) + 0.5;
      }

    }
  """;

  public function new() {
    super(vertexShader, fragmentShader);
    this.uniforms = uniforms;
  }

}


**Explanation:**

1. **Class Declaration:**
   - The code defines a `BrightnessContrastShader` class that inherits from the `Shader` class in OpenFL.

2. **Static Variables:**
   - `name`: Stores the name of the shader ("BrightnessContrastShader").
   - `uniforms`: A `Map` to store the shader's uniform variables. Each uniform is defined with its name and type using `ShaderInput` (for samplers) and `ShaderParameter` (for other types).
   - `vertexShader` and `fragmentShader`: Strings containing the GLSL code for the vertex and fragment shaders.

3. **Constructor:**
   - The constructor calls the superclass constructor, passing the vertex and fragment shader strings.
   - It then sets the `uniforms` property of the `Shader` instance to the `uniforms` map defined earlier.

**Using the Shader:**

To use this shader, you would create an instance of `BrightnessContrastShader` and apply it to a `Sprite` or other display object. You can then set the values of the uniforms, such as `brightness` and `contrast`, to adjust the effect.

**Example:**


import openfl.display.Sprite;
import openfl.display.BitmapData;

// ... (rest of the code)

var sprite:Sprite = new Sprite();
var bitmapData:BitmapData = new BitmapData(100, 100);
sprite.graphics.beginBitmapFill(bitmapData);
sprite.graphics.drawRect(0, 0, 100, 100);
sprite.graphics.endFill();

var shader:BrightnessContrastShader = new BrightnessContrastShader();
shader.uniforms.get("brightness").value = 0.5;
shader.uniforms.get("contrast").value = 0.2;
sprite.filters = [shader];

addChild(sprite);