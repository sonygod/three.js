package;

class ColorCorrectionShader {
	public var name: String = 'ColorCorrectionShader';
	public var uniforms: { [key: String]: dynamic } = {
		'tDiffuse': { value: null },
		'powRGB': { value: new openfl.geom.Vector3D(2, 2, 2) },
		'mulRGB': { value: new openfl.geom.Vector3D(1, 1, 1) },
		'addRGB': { value: new openfl.geom.Vector3D(0, 0, 0) }
	};
	public var vertexShader: String = '
		varying vec2 vUv;
		void main() {
			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
		}
	';
	public var fragmentShader: String = '
		uniform sampler2D tDiffuse;
		uniform vec3 powRGB;
		uniform vec3 mulRGB;
		uniform vec3 addRGB;
		varying vec2 vUv;
		void main() {
			gl_FragColor = texture2D(tDiffuse, vUv);
			gl_FragColor.rgb = mulRGB * pow((gl_FragColor.rgb + addRGB), powRGB);
		}
	';

	public function new() {

	}
}