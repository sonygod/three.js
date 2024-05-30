package;

class GammaCorrectionShader {
	public var name: String = 'GammaCorrectionShader';
	public var uniforms: { tDiffuse: { value: Dynamic } } = {
		'tDiffuse': { value: null }
	};

	public var vertexShader = '''
		varying vec2 vUv;

		void main() {

			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}
	''';

	public var fragmentShader = '''
		uniform sampler2D tDiffuse;

		varying vec2 vUv;

		void main() {

			vec4 tex = texture2D( tDiffuse, vUv );

			gl_FragColor = sRGBTransferOETF( tex );

		}
	''';

	public function new() {

	}
}