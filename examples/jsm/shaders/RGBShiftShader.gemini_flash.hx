import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class RGBShiftShader extends Shader {

	public static var name:String = "RGBShiftShader";

	public static var uniforms:Map<String, ShaderParameter> = new Map<String, ShaderParameter>([
		["tDiffuse", new ShaderParameter(ShaderInput.TEXTURE)],
		["amount", new ShaderParameter(ShaderInput.FLOAT)],
		["angle", new ShaderParameter(ShaderInput.FLOAT)]
	]);

	public static var vertexShader:String = """
		varying vec2 vUv;

		void main() {

			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}
	""";

	public static var fragmentShader:String = """
		uniform sampler2D tDiffuse;
		uniform float amount;
		uniform float angle;

		varying vec2 vUv;

		void main() {

			vec2 offset = amount * vec2( cos(angle), sin(angle));
			vec4 cr = texture2D(tDiffuse, vUv + offset);
			vec4 cga = texture2D(tDiffuse, vUv);
			vec4 cb = texture2D(tDiffuse, vUv - offset);
			gl_FragColor = vec4(cr.r, cga.g, cb.b, cga.a);

		}
	""";

	public function new() {
		super(vertexShader, fragmentShader, uniforms);
	}
}



**Explanation:**

1. **Class Definition:** The code defines a new Haxe class `RGBShiftShader` that inherits from `openfl.display.Shader`.

2. **Static Properties:**
   - `name`:  A string variable holding the name of the shader.
   - `uniforms`: A map that defines the shader's uniform variables. Each entry in the map is a key-value pair, where the key is the uniform name and the value is a `ShaderParameter` object. 
   - `vertexShader`: A string containing the GLSL code for the vertex shader.
   - `fragmentShader`: A string containing the GLSL code for the fragment shader.

3. **Constructor:**
   - The constructor of the class calls the superclass constructor, passing the vertex shader, fragment shader, and uniforms as arguments.

4. **Shader Input Types:**
   - `ShaderInput.TEXTURE`: Indicates that the uniform variable is a texture sampler.
   - `ShaderInput.FLOAT`: Indicates that the uniform variable is a floating-point number.

**Usage:**

To use the `RGBShiftShader` in Haxe, you would create an instance of it and then apply it to a `Sprite` or other display object:


// Create an instance of the shader
var shader:RGBShiftShader = new RGBShiftShader();

// Create a Sprite and apply the shader
var sprite:Sprite = new Sprite();
sprite.filters = [new ShaderFilter(shader)];