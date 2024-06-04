import three.Vector2;

/**
 * Dot screen shader
 * based on glfx.js sepia shader
 * https://github.com/evanw/glfx.js
 */
class DotScreenShader {

	public static var name:String = "DotScreenShader";

	public static var uniforms:Dynamic = {
		"tDiffuse": { value: null },
		"tSize": { value: new Vector2(256, 256) },
		"center": { value: new Vector2(0.5, 0.5) },
		"angle": { value: 1.57 },
		"scale": { value: 1.0 }
	};

	public static var vertexShader:String = /* glsl */`

		varying vec2 vUv;

		void main() {

			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}`;

	public static var fragmentShader:String = /* glsl */`

		uniform vec2 center;
		uniform float angle;
		uniform float scale;
		uniform vec2 tSize;

		uniform sampler2D tDiffuse;

		varying vec2 vUv;

		float pattern() {

			float s = sin( angle ), c = cos( angle );

			vec2 tex = vUv * tSize - center;
			vec2 point = vec2( c * tex.x - s * tex.y, s * tex.x + c * tex.y ) * scale;

			return ( sin( point.x ) * sin( point.y ) ) * 4.0;

		}

		void main() {

			vec4 color = texture2D( tDiffuse, vUv );

			float average = ( color.r + color.g + color.b ) / 3.0;

			gl_FragColor = vec4( vec3( average * 10.0 - 5.0 + pattern() ), color.a );

		}`;

}


**Explanation of Changes:**

1. **Class Definition:**
   - The code is wrapped in a class named `DotScreenShader` instead of an object. This aligns better with Haxe's object-oriented nature.

2. **Static Members:**
   -  `name`, `uniforms`, `vertexShader`, and `fragmentShader` are declared as `static` members of the class. This makes them accessible without creating an instance of the class.

3. **Dynamic Type:**
   - The `uniforms` member is declared as a `Dynamic` to represent a dictionary-like structure in Haxe. This allows you to store key-value pairs, similar to JavaScript objects.

4. **String Literals:**
   - Haxe uses `/* glsl */` before string literals to indicate they contain GLSL code. This is a convention for better readability.

5. **Vector2:**
   - The `Vector2` class is imported from the `three` library, assuming you have it included in your project.

**Usage:**

You can use the `DotScreenShader` class like this:


// Assuming you have a reference to a Three.js renderer or scene.
// ...

// Access static members
var shaderName = DotScreenShader.name;
var shaderUniforms = DotScreenShader.uniforms;
var vertexShaderCode = DotScreenShader.vertexShader;
var fragmentShaderCode = DotScreenShader.fragmentShader;

// Use the shader code as needed to create a material or shader program.