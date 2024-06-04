import three.Vector2;

/**
 * Edge Detection Shader using Frei-Chen filter
 * Based on http://rastergrid.com/blog/2011/01/frei-chen-edge-detector
 *
 * aspect: vec2 of (1/width, 1/height)
 */

class FreiChenShader {

	public static var name:String = "FreiChenShader";

	public static var uniforms:Map<String,Dynamic> = new Map<String,Dynamic>()
		.set('tDiffuse', { value: null })
		.set('aspect', { value: new Vector2(512, 512) });

	public static var vertexShader:String = /* glsl */`
		varying vec2 vUv;

		void main() {

			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}`;

	public static var fragmentShader:String = /* glsl */`

		uniform sampler2D tDiffuse;
		varying vec2 vUv;

		uniform vec2 aspect;

		vec2 texel = vec2( 1.0 / aspect.x, 1.0 / aspect.y );


		mat3 G[9];

		// hard coded matrix values!!!! as suggested in https://github.com/neilmendoza/ofxPostProcessing/blob/master/src/EdgePass.cpp#L45

		const mat3 g0 = mat3( 0.3535533845424652, 0, -0.3535533845424652, 0.5, 0, -0.5, 0.3535533845424652, 0, -0.3535533845424652 );
		const mat3 g1 = mat3( 0.3535533845424652, 0.5, 0.3535533845424652, 0, 0, 0, -0.3535533845424652, -0.5, -0.3535533845424652 );
		const mat3 g2 = mat3( 0, 0.3535533845424652, -0.5, -0.3535533845424652, 0, 0.3535533845424652, 0.5, -0.3535533845424652, 0 );
		const mat3 g3 = mat3( 0.5, -0.3535533845424652, 0, -0.3535533845424652, 0, 0.3535533845424652, 0, 0.3535533845424652, -0.5 );
		const mat3 g4 = mat3( 0, -0.5, 0, 0.5, 0, 0.5, 0, -0.5, 0 );
		const mat3 g5 = mat3( -0.5, 0, 0.5, 0, 0, 0, 0.5, 0, -0.5 );
		const mat3 g6 = mat3( 0.1666666716337204, -0.3333333432674408, 0.1666666716337204, -0.3333333432674408, 0.6666666865348816, -0.3333333432674408, 0.1666666716337204, -0.3333333432674408, 0.1666666716337204 );
		const mat3 g7 = mat3( -0.3333333432674408, 0.1666666716337204, -0.3333333432674408, 0.1666666716337204, 0.6666666865348816, 0.1666666716337204, -0.3333333432674408, 0.1666666716337204, -0.3333333432674408 );
		const mat3 g8 = mat3( 0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408 );

		void main(void)
		{

			G[0] = g0;
			G[1] = g1;
			G[2] = g2;
			G[3] = g3;
			G[4] = g4;
			G[5] = g5;
			G[6] = g6;
			G[7] = g7;
			G[8] = g8;

			mat3 I;
			float cnv[9];
			vec3 sample;

		/* fetch the 3x3 neighbourhood and use the RGB vector's length as intensity value */
			for (float i=0.0; i<3.0; i++) {
				for (float j=0.0; j<3.0; j++) {
					sample = texture2D(tDiffuse, vUv + texel * vec2(i-1.0,j-1.0) ).rgb;
					I[int(i)][int(j)] = length(sample);
				}
			}

		/* calculate the convolution values for all the masks */
			for (int i=0; i<9; i++) {
				float dp3 = dot(G[i][0], I[0]) + dot(G[i][1], I[1]) + dot(G[i][2], I[2]);
				cnv[i] = dp3 * dp3;
			}

			float M = (cnv[0] + cnv[1]) + (cnv[2] + cnv[3]);
			float S = (cnv[4] + cnv[5]) + (cnv[6] + cnv[7]) + (cnv[8] + M);

			gl_FragColor = vec4(vec3(sqrt(M/S)), 1.0);
		}`
}



**Explanation of changes:**

* **Class instead of object:** In Haxe, we typically use classes to represent data and functionality.  
* **`Map` for `uniforms`:**  Haxe uses `Map` for key-value pairs.
* **`const` for matrix values:** Haxe uses `const` to declare constants.
* **No `export` keyword:**  Haxe doesn't have an `export` keyword. You can directly use the `FreiChenShader` class in other parts of your project.

**How to use in your Haxe project:**

1. **Add the `three` library:** Make sure you have the `three` library installed in your Haxe project. You can use `haxelib install three`.
2. **Create a shader material:** Create a `ShaderMaterial` using the `FreiChenShader` class:


import three.ShaderMaterial;

var material = new ShaderMaterial(FreiChenShader.uniforms, FreiChenShader.vertexShader, FreiChenShader.fragmentShader);


3. **Apply the material to your mesh:** Assign the material to a mesh that you want to apply the edge detection effect to.


var mesh = new Mesh(geometry, material);