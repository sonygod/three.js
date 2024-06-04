import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class HueSaturationShader extends Shader {

	public static var name:String = "HueSaturationShader";

	public function new() {
		super();
		this.vertexSource =
			"varying vec2 vUv;\n" +
			"void main() {\n" +
			"	vUv = uv;\n" +
			"	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n" +
			"}";
		this.fragmentSource =
			"uniform sampler2D tDiffuse;\n" +
			"uniform float hue;\n" +
			"uniform float saturation;\n" +
			"varying vec2 vUv;\n" +
			"void main() {\n" +
			"	gl_FragColor = texture2D( tDiffuse, vUv );\n" +
			"	// hue\n" +
			"	float angle = hue * 3.14159265;\n" +
			"	float s = sin(angle), c = cos(angle);\n" +
			"	vec3 weights = (vec3(2.0 * c, -sqrt(3.0) * s - c, sqrt(3.0) * s - c) + 1.0) / 3.0;\n" +
			"	float len = length(gl_FragColor.rgb);\n" +
			"	gl_FragColor.rgb = vec3(\n" +
			"		dot(gl_FragColor.rgb, weights.xyz),\n" +
			"		dot(gl_FragColor.rgb, weights.zxy),\n" +
			"		dot(gl_FragColor.rgb, weights.yzx)\n" +
			"	);\n" +
			"	// saturation\n" +
			"	float average = (gl_FragColor.r + gl_FragColor.g + gl_FragColor.b) / 3.0;\n" +
			"	if (saturation > 0.0) {\n" +
			"		gl_FragColor.rgb += (average - gl_FragColor.rgb) * (1.0 - 1.0 / (1.001 - saturation));\n" +
			"	} else {\n" +
			"		gl_FragColor.rgb += (average - gl_FragColor.rgb) * (-saturation);\n" +
			"	}\n" +
			"}";
		this.input = new ShaderInput();
		this.input.add("tDiffuse", new ShaderParameter(ShaderParameter.TYPE_SAMPLER2D));
		this.input.add("hue", new ShaderParameter(ShaderParameter.TYPE_FLOAT));
		this.input.add("saturation", new ShaderParameter(ShaderParameter.TYPE_FLOAT));
	}

}


**Explanation:**

1. **Import necessary classes:**
   - `openfl.display.Shader`: The base class for creating shaders.
   - `openfl.display.ShaderInput`: Used to define input parameters for the shader.
   - `openfl.display.ShaderParameter`: Represents a single parameter for the shader.

2. **Create `HueSaturationShader` class:**
   - Extends the `Shader` class.
   - Defines a static `name` property for identification.

3. **Constructor:**
   - Calls the superclass constructor (`super()`).
   - Sets the `vertexSource` and `fragmentSource` properties with the GLSL code.
   - Creates a `ShaderInput` object to hold the shader's inputs.
   - Adds three input parameters:
     - `tDiffuse`: A sampler2D for the input texture.
     - `hue`: A float for the hue adjustment value.
     - `saturation`: A float for the saturation adjustment value.

**Usage Example:**


import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Stage;

class Main extends Sprite {

	public function new() {
		super();

		// Load an image
		var bitmapData:BitmapData = new BitmapData(100, 100, true, 0xFFFFFF);
		// ... (Populate bitmapData with an image)

		// Create a bitmap from the bitmapData
		var bitmap:Bitmap = new Bitmap(bitmapData);
		addChild(bitmap);

		// Create the HueSaturationShader
		var shader:HueSaturationShader = new HueSaturationShader();

		// Set shader parameters
		shader.input.set("hue", 0.5);
		shader.input.set("saturation", 0.2);

		// Apply the shader to the bitmap
		bitmap.filters = [shader];
	}

}