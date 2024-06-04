import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.geom.Rectangle;

class LuminosityShader extends Shader {

	public static var name:String = "LuminosityShader";

	public function new() {
		super(
			`
			varying vec2 vUv;

			void main() {

				vUv = uv;

				gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

			}
			`,
			`
			#include <common>

			uniform sampler2D tDiffuse;

			varying vec2 vUv;

			void main() {

				vec4 texel = texture2D( tDiffuse, vUv );

				float l = luminance( texel.rgb );

				gl_FragColor = vec4( l, l, l, texel.w );

			}
			`
		);

		var tDiffuse:ShaderParameter = new ShaderParameter(ShaderInput.TEXTURE);
		tDiffuse.name = "tDiffuse";
		parameters.set("tDiffuse", tDiffuse);
	}

	public function setTexture(texture:openfl.display.BitmapData):Void {
		parameters.get("tDiffuse").value = texture;
	}
}


**Explanation:**

* **Class Definition:** The code defines a class named `LuminosityShader` that extends the `openfl.display.Shader` class.
* **Constructor:** The constructor initializes the shader with the vertex and fragment shaders provided.
* **Shader Parameters:** A `ShaderParameter` object is created for the `tDiffuse` uniform, which is set to `ShaderInput.TEXTURE` to indicate that it's a texture input. The parameter is then added to the `parameters` dictionary of the shader.
* **setTexture Method:** A `setTexture` method is added to allow setting the texture value for the `tDiffuse` uniform. This method takes a `openfl.display.BitmapData` object as input.

**Usage:**


// Create a LuminosityShader instance
var shader:LuminosityShader = new LuminosityShader();

// Create a BitmapData object for the texture
var texture:openfl.display.BitmapData = new openfl.display.BitmapData(100, 100);

// Set the texture for the shader
shader.setTexture(texture);

// Use the shader in a Sprite or other display object
var sprite:openfl.display.Sprite = new openfl.display.Sprite();
sprite.shader = shader;