class WebGLShader {

	public static function new(gl: WebGLRenderingContext, type: Int, string: String): WebGLShader {
		var shader = gl.createShader(type);
		gl.shaderSource(shader, string);
		gl.compileShader(shader);
		return new WebGLShader(shader);
	}

	public var shader: WebGLShader;

	function new(shader: WebGLShader) {
		this.shader = shader;
	}

}


Here's a breakdown of the conversion:

**1. Class Structure:**

- In Haxe, we create a class `WebGLShader` to encapsulate the shader object.
- The `new` function is used to create instances of the class.

**2. Static Function:**

- We use a static function `new` within the `WebGLShader` class to handle shader creation. This keeps the creation logic within the class and avoids unnecessary object creation.

**3. Type Conversion:**

- Haxe uses `Int` for integers instead of `number` in JavaScript.
- We use `WebGLRenderingContext` to represent the `gl` object.

**4. Member Variable:**

- We store the actual `WebGLShader` object in a member variable `shader` for easy access within the class.

**5. Constructor:**

- The constructor takes the `WebGLShader` object as an argument and assigns it to the `shader` member variable.

**6. Export:**

- Haxe doesn't use `export` like JavaScript. You can use the `--lib haxe.extern.webgl` flag when compiling to generate the necessary extern code for WebGL.

**Usage Example:**


import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.utils.Assets;

class Main extends Sprite {

	public var gl: WebGLRenderingContext;

	override function createChildren(): Void {
		super.createChildren();

		// ... (set up WebGL context)

		// Create vertex shader
		var vertexShader = WebGLShader.new(gl, gl.VERTEX_SHADER, Assets.getText("vertex.glsl"));

		// ... (Create fragment shader and link program)
	}

}