import three.Vector2;

class NormalMapShader {

	public static var name:String = "NormalMapShader";

	public static var uniforms:Dynamic = {
		"heightMap": { value: null },
		"resolution": { value: new Vector2(512, 512) },
		"scale": { value: new Vector2(1, 1) },
		"height": { value: 0.05 }
	};

	public static var vertexShader:String = /* glsl */`

		varying vec2 vUv;

		void main() {

			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}`;

	public static var fragmentShader:String = /* glsl */`

		uniform float height;
		uniform vec2 resolution;
		uniform sampler2D heightMap;

		varying vec2 vUv;

		void main() {

			float val = texture2D( heightMap, vUv ).x;

			float valU = texture2D( heightMap, vUv + vec2( 1.0 / resolution.x, 0.0 ) ).x;
			float valV = texture2D( heightMap, vUv + vec2( 0.0, 1.0 / resolution.y ) ).x;

			gl_FragColor = vec4( ( 0.5 * normalize( vec3( val - valU, val - valV, height  ) ) + 0.5 ), 1.0 );

		}`;

}


**Explanation of Changes:**

* **Import:** We import `Vector2` from `three`.
* **Class:** We define a class named `NormalMapShader` instead of an object literal.
* **Static Variables:** All properties are declared as `static` since they represent shared data for the shader.
* **Dynamic Type:** The `uniforms` property is declared as `Dynamic` to represent a dynamic object, as in JavaScript.
* **String Literals:** We use `/* glsl */` before the shader code to indicate that it is GLSL code.

**Usage:**

The `NormalMapShader` class can be used in a similar way to the JavaScript version. You can access its properties directly, for example:


NormalMapShader.uniforms.resolution.value = new Vector2(1024, 1024);