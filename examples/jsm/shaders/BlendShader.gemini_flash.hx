import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class BlendShader extends Shader {

	public static var name:String = "BlendShader";

	public var tDiffuse1:ShaderInput;
	public var tDiffuse2:ShaderInput;
	public var mixRatio:ShaderInput;
	public var opacity:ShaderInput;

	public function new() {
		super();

		tDiffuse1 = new ShaderInput(ShaderInput.SAMPLER2D, "tDiffuse1");
		tDiffuse2 = new ShaderInput(ShaderInput.SAMPLER2D, "tDiffuse2");
		mixRatio = new ShaderInput(ShaderInput.FLOAT, "mixRatio");
		opacity = new ShaderInput(ShaderInput.FLOAT, "opacity");

		parameters.set(tDiffuse1);
		parameters.set(tDiffuse2);
		parameters.set(mixRatio);
		parameters.set(opacity);

		vertexSource = "varying vec2 vUv;\nvoid main() {\nvUv = uv;\ngl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n}";
		fragmentSource = "uniform float opacity;\nuniform float mixRatio;\nuniform sampler2D tDiffuse1;\nuniform sampler2D tDiffuse2;\nvarying vec2 vUv;\nvoid main() {\nvec4 texel1 = texture2D( tDiffuse1, vUv );\nvec4 texel2 = texture2D( tDiffuse2, vUv );\ngl_FragColor = opacity * mix( texel1, texel2, mixRatio );\n}";
	}
}


**Explanation of Changes:**

* **Class Structure:** The code is encapsulated within a `BlendShader` class.
* **Shader Inputs:**  Instead of using an object with `uniforms`, the `BlendShader` class directly has public properties `tDiffuse1`, `tDiffuse2`, `mixRatio`, and `opacity`. These properties are instances of `ShaderInput` class, which represent the inputs to the shader.
* **ShaderInput Initialization:** In the constructor, we create instances of `ShaderInput` for each uniform and set their type and name.
* **Shader Parameters:** The `parameters` property of the `Shader` class is used to store the shader inputs. We use the `set` method to add each input to the parameters.
* **Vertex and Fragment Source:** The `vertexSource` and `fragmentSource` strings contain the GLSL code for the vertex and fragment shaders, respectively.

**How to Use:**

1. **Create an instance:**
   
   var blendShader:BlendShader = new BlendShader();
   

2. **Set input values:**
   
   blendShader.tDiffuse1.value = someTexture1; 
   blendShader.tDiffuse2.value = someTexture2; 
   blendShader.mixRatio.value = 0.5;
   blendShader.opacity.value = 1.0;
   

3. **Apply the shader:**
   
   someSprite.shader = blendShader;