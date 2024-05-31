package three.examples.jsm.shaders;

import js.lib.three.UniformsUtils;
import js.lib.three.ShaderLib;
import js.lib.three.ShaderMaterial;
import js.lib.three.Uniforms;
import js.lib.three.Vector2;
import js.lib.three.Texture;

class HorizontalBlurShader {

	public static var name:String = 'HorizontalBlurShader';

	public static var uniforms:Uniforms = UniformsUtils.merge([
		ShaderLib.common.uniforms, {
			'tDiffuse': { value: null },
			'h': { value: 1.0 / 512.0 }
		}
	]);

	public static var vertexShader:String = [
		'varying vec2 vUv;',

		'void main() {',
		'	vUv = uv;',
		'	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
		'}'
	].join('\n');

	public static var fragmentShader:String = [
		'uniform sampler2D tDiffuse;',
		'uniform float h;',

		'varying vec2 vUv;',

		'void main() {',
		'	vec4 sum = vec4( 0.0 );',

		'	sum += texture2D( tDiffuse, vec2( vUv.x - 4.0 * h, vUv.y ) ) * 0.051;',
		'	sum += texture2D( tDiffuse, vec2( vUv.x - 3.0 * h, vUv.y ) ) * 0.0918;',
		'	sum += texture2D( tDiffuse, vec2( vUv.x - 2.0 * h, vUv.y ) ) * 0.12245;',
		'	sum += texture2D( tDiffuse, vec2( vUv.x - 1.0 * h, vUv.y ) ) * 0.1531;',
		'	sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y ) ) * 0.1633;',
		'	sum += texture2D( tDiffuse, vec2( vUv.x + 1.0 * h, vUv.y ) ) * 0.1531;',
		'	sum += texture2D( tDiffuse, vec2( vUv.x + 2.0 * h, vUv.y ) ) * 0.12245;',
		'	sum += texture2D( tDiffuse, vec2( vUv.x + 3.0 * h, vUv.y ) ) * 0.0918;',
		'	sum += texture2D( tDiffuse, vec2( vUv.x + 4.0 * h, vUv.y ) ) * 0.051;',

		'	gl_FragColor = sum;',
		'}'
	].join('\n');

	public static function getShader(tDiffuse:Texture):ShaderMaterial {
		var shader = new ShaderMaterial({
			uniforms: uniforms,
			vertexShader: vertexShader,
			fragmentShader: fragmentShader
		});
		shader.uniforms['tDiffuse'].value = tDiffuse;
		return shader;
	}
}