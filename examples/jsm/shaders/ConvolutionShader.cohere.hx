import js.three.Vector2;

class ConvolutionShader {
	public static var name: String = 'ConvolutionShader';
	public static var defines: { [key: String]: String } = {
		'KERNEL_SIZE_FLOAT': '25.0',
		'KERNEL_SIZE_INT': '25'
	};
	public static var uniforms: { [key: String]: { value: Dynamic } } = {
		'tDiffuse': { value: null },
		'uImageIncrement': { value: new Vector2(0.001953125, 0.0) },
		'cKernel': { value: [] }
	};
	public static var vertexShader: String = '''
		uniform vec2 uImageIncrement;

		varying vec2 vUv;

		void main() {

			vUv = uv - ( ( ${'KERNEL_SIZE_FLOAT'} - 1.0 ) / 2.0 ) * uImageIncrement;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}
	''';
	public static var fragmentShader: String = '''
		uniform float cKernel[ ${'KERNEL_SIZE_INT'} ];

		uniform sampler2D tDiffuse;
		uniform vec2 uImageIncrement;

		varying vec2 vUv;

		void main() {

			vec2 imageCoord = vUv;
			vec4 sum = vec4( 0.0, 0.0, 0.0, 0.0 );

			for( int i = 0; i < ${'KERNEL_SIZE_INT'}; i ++ ) {

				sum += texture2D( tDiffuse, imageCoord ) * cKernel[ i ];
				imageCoord += uImageIncrement;

			}

			gl_FragColor = sum;

		}
	''';

	public static function buildKernel(sigma: Float) -> Array<Float> {
		var kMaxKernelSize: Int = 25;
		var kernelSize: Int = Std.int(2.0 * Math.ceil(sigma * 3.0)) + 1;

		if (kernelSize > kMaxKernelSize) {
			kernelSize = kMaxKernelSize;
		}

		var halfWidth: Int = (kernelSize - 1) ~/ 2;
		var values: Array<Float> = [];
		var sum: Float = 0.0;

		for (i in 0...kernelSize) {
			var x: Int = i - halfWidth;
			values.push(gauss(x, sigma));
			sum += values[i];
		}

		for (i in 0...kernelSize) {
			values[i] /= sum;
		}

		return values;
	}

	private static inline function gauss(x: Int, sigma: Float) -> Float {
		return Math.exp(-(Float(x) * Float(x)) / (2.0 * sigma * sigma));
	}
}