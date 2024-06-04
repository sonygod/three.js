import three.Color;

/**
 * Colorify shader
 */

class ColorifyShader {

	public static var name:String = "ColorifyShader";

	public static var uniforms:Dynamic = {
		"tDiffuse": { value: null },
		"color": { value: new Color(0xFFFFFF) }
	};

	public static var vertexShader:String = /* glsl */`
		varying vec2 vUv;

		void main() {

			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}`;

	public static var fragmentShader:String = /* glsl */`

		uniform vec3 color;
		uniform sampler2D tDiffuse;

		varying vec2 vUv;

		void main() {

			vec4 texel = texture2D( tDiffuse, vUv );

			vec3 luma = vec3( 0.299, 0.587, 0.114 );
			float v = dot( texel.xyz, luma );

			gl_FragColor = vec4( v * color, texel.w );

		}`;

}

class ColorifyShader {

	public static function main() {
		// No need for a main function in Haxe, the class itself acts as the entry point
	}
}


**Explanation of Changes:**

1. **Class Declaration:** Haxe uses classes for everything. Instead of an object literal, we define a `ColorifyShader` class. 
2. **Static Members:**  We use `public static` to declare the `name`, `uniforms`, `vertexShader`, and `fragmentShader` properties. This makes them accessible directly from the `ColorifyShader` class without needing to instantiate an object.
3. **Type Annotations:**  Haxe uses type annotations. We've added type annotations like `String` and `Dynamic` to improve code clarity and allow for better type checking.
4. **Dynamic Object:**  The `uniforms` property remains a `Dynamic` object, as Haxe doesn't have a direct equivalent to JavaScript's plain object literals. This allows you to access and modify the uniforms dynamically.
5. **Main Function:** In Haxe, the `main` function is generally used for entry points. We've added a `main` function to the `ColorifyShader` class, but it's currently empty because the class itself acts as the entry point in this case.

**How to Use:**


// Import the ColorifyShader class
import ColorifyShader;

// ... rest of your code ...

// Access shader properties
var name:String = ColorifyShader.name;
var uniforms:Dynamic = ColorifyShader.uniforms;

// Use the shaders in your Three.js code