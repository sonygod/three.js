import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class ExposureShader extends Shader {

  public static var name:String = "ExposureShader";

  public static var uniforms:Map<String, ShaderInput> = new Map<String, ShaderInput>([
    ["tDiffuse", new ShaderInput(ShaderParameter.sampler2D, null)],
    ["exposure", new ShaderInput(ShaderParameter.float, 1.0)]
  ]);

  public static var vertexShader:String =
    `varying vec2 vUv;

    void main() {

      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

    }`;

  public static var fragmentShader:String =
    `uniform float exposure;

    uniform sampler2D tDiffuse;

    varying vec2 vUv;

    void main() {

      gl_FragColor = texture2D( tDiffuse, vUv );
      gl_FragColor.rgb *= exposure;

    }`;

}


**Explanation:**

1. **Import Necessary Classes:**
   - `openfl.display.Shader`: The base class for shaders in Haxe.
   - `openfl.display.ShaderInput`: Represents a shader input parameter.
   - `openfl.display.ShaderParameter`: Defines the types of shader parameters.

2. **Class Definition:**
   - Create a class `ExposureShader` that extends the `Shader` class.

3. **Static Properties:**
   - `name`: Stores the shader name as a string.
   - `uniforms`: A `Map` to store the shader uniforms. Each key is the uniform name, and the value is a `ShaderInput` object.
   - `vertexShader`: Contains the GLSL vertex shader code.
   - `fragmentShader`: Contains the GLSL fragment shader code.

4. **Shader Input Creation:**
   - `uniforms`: Create `ShaderInput` objects for each uniform. The first parameter specifies the type of the parameter using `ShaderParameter`. The second parameter provides the initial value.

5. **GLSL Code:**
   - The `vertexShader` and `fragmentShader` properties contain the GLSL code, which remains the same as the JavaScript example.

**Usage:**

To use the `ExposureShader` in Haxe, create an instance of the class and assign it to a display object's `shader` property. Then, update the shader's uniform values using the `setUniform` method.


// Create an instance of the ExposureShader
var exposureShader:ExposureShader = new ExposureShader();

// Assign the shader to a display object
myDisplayObject.shader = exposureShader;

// Set the uniform values
exposureShader.setUniform("tDiffuse", myTexture);
exposureShader.setUniform("exposure", 1.5);