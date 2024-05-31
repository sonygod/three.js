package three.examples.jsm.shaders;

import js.html.WebGLRenderingContext;
import js.html.WebGLUniformLocation;
import three.js.UniformsUtils;
import three.js.ShaderLib;
import three.js.ShaderMaterial;
import three.js.ShaderChunk;

class HorizontalTiltShiftShader {

	public static var name:String = 'HorizontalTiltShiftShader';

	public static var uniforms:Dynamic = {

		'tDiffuse': { value: null },
		'h': { value: 1.0 / 512.0 },
		'r': { value: 0.35 }

	};

	public static var vertexShader:String = /* glsl */`

		varying vec2 vUv;

		void main() {

			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}
	`;

	public static var fragmentShader:String = /* glsl */`

		uniform sampler2D tDiffuse;
		uniform float h;
		uniform float r;

		varying vec2 vUv;

		void main() {

			vec4 sum = vec4( 0.0 );

			float hh = h * abs( r - vUv.y );

			sum += texture2D( tDiffuse, vec2( vUv.x - 4.0 * hh, vUv.y ) ) * 0.051;
			sum += texture2D( tDiffuse, vec2( vUv.x - 3.0 * hh, vUv.y ) ) * 0.0918;
			sum += texture2D( tDiffuse, vec2( vUv.x - 2.0 * hh, vUv.y ) ) * 0.12245;
			sum += texture2D( tDiffuse, vec2( vUv.x - 1.0 * hh, vUv.y ) ) * 0.1531;
			sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y ) ) * 0.1633;
			sum += texture2D( tDiffuse, vec2( vUv.x + 1.0 * hh, vUv.y ) ) * 0.1531;
			sum += texture2D( tDiffuse, vec2( vUv.x + 2.0 * hh, vUv.y ) ) * 0.12245;
			sum += texture2D( tDiffuse, vec2( vUv.x + 3.0 * hh, vUv.y ) ) * 0.0918;
			sum += texture2D( tDiffuse, vec2( vUv.x + 4.0 * hh, vUv.y ) ) * 0.051;

			gl_FragColor = sum;

		}
	`;

	public static function getShader():ShaderMaterial {

		var shader = ShaderLib[name];

		if (shader == null) {

			var uniforms = UniformsUtils.clone(uniforms);

			var vertexShader = ShaderChunk.getVertexShader(name);
			var fragmentShader = ShaderChunk.getFragmentShader(name);

			shader = new ShaderMaterial({
				uniforms: uniforms,
				vertexShader: vertexShader,
				fragmentShader: fragmentShader
			});

			ShaderLib[name] = shader;

		}

		return shader;

	}

}