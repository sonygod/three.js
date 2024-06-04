import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class AfterimageShader extends Shader {

	public static var name:String = "AfterimageShader";

	public var damp:ShaderParameter;
	public var tOld:ShaderParameter;
	public var tNew:ShaderParameter;

	public function new() {
		super();

		this.damp = new ShaderParameter(ShaderInput.Float, 0.96);
		this.tOld = new ShaderParameter(ShaderInput.Texture, null);
		this.tNew = new ShaderParameter(ShaderInput.Texture, null);

		this.vertexShader = """
			varying vec2 vUv;

			void main() {

				vUv = uv;
				gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

			}
		""";

		this.fragmentShader = """
			uniform float damp;

			uniform sampler2D tOld;
			uniform sampler2D tNew;

			varying vec2 vUv;

			vec4 when_gt( vec4 x, float y ) {

				return max( sign( x - y ), 0.0 );

			}

			void main() {

				vec4 texelOld = texture2D( tOld, vUv );
				vec4 texelNew = texture2D( tNew, vUv );

				texelOld *= damp * when_gt( texelOld, 0.1 );

				gl_FragColor = max(texelNew, texelOld);

			}
		""";
	}
}


**Explanation:**

1. **Imports:** We import necessary classes from the OpenFL library: `Shader`, `ShaderInput`, and `ShaderParameter`.
2. **Class Definition:** The `AfterimageShader` class is defined, extending the `Shader` class.
3. **Static Name:** We define the `name` property as a static String, similar to the JavaScript version.
4. **Shader Parameters:** We create `ShaderParameter` instances for `damp`, `tOld`, and `tNew` to represent the shader uniforms.
5. **Constructor:** In the constructor, we initialize the `damp` parameter with a default value of 0.96. The `tOld` and `tNew` parameters are initially set to `null`.
6. **Vertex Shader:** The vertex shader remains the same, using the `varying` keyword to pass the texture coordinate `vUv` to the fragment shader.
7. **Fragment Shader:** The fragment shader is also identical to the JavaScript version, using GLSL syntax and uniform variables.

**To use this Haxe shader:**

1. Create an instance of `AfterimageShader`.
2. Set the values of the shader parameters (e.g., `shader.damp = 0.95`).
3. Apply the shader to a `Sprite` or other display object.

**Example:**


import openfl.display.Sprite;
import openfl.display.BitmapData;

class Main extends Sprite {

	public static function main():Void {
		new Main();
	}

	public function new() {
		super();

		// Create a BitmapData to hold the texture
		var texture:BitmapData = new BitmapData(100, 100);

		// Create an instance of the AfterimageShader
		var shader:AfterimageShader = new AfterimageShader();

		// Set the shader parameters
		shader.tNew = new ShaderParameter(ShaderInput.Texture, texture);

		// Apply the shader to a Sprite
		var sprite:Sprite = new Sprite();
		sprite.shader = shader;

		// Add the sprite to the stage
		addChild(sprite);
	}
}