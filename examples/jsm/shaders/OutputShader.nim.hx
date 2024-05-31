package three.examples.jsm.shaders;

import js.html.WebGLRenderingContext;
import three.js.UniformsUtils;
import three.js.ShaderLib;
import three.js.ShaderMaterial;
import three.js.ShaderChunk;

class OutputShader {

	public static var name:String = 'OutputShader';

	public static var uniforms:Dynamic = UniformsUtils.merge([
		ShaderLib.common.uniforms,
		ShaderLib.lights.uniforms,
		{
			'tDiffuse': { value: null },
			'toneMappingExposure': { value: 1 }
		}
	]);

	public static var vertexShader:String = [
		'precision highp float;',
		'',
		'uniform mat4 modelViewMatrix;',
		'uniform mat4 projectionMatrix;',
		'',
		'attribute vec3 position;',
		'attribute vec2 uv;',
		'',
		'varying vec2 vUv;',
		'',
		'void main() {',
		'',
		'	vUv = uv;',
		'	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
		'',
		'}'
	].join('\n');

	public static var fragmentShader:String = [
		'precision highp float;',
		'',
		'uniform sampler2D tDiffuse;',
		'',
		ShaderChunk.tonemapping_pars_fragment,
		ShaderChunk.colorspace_pars_fragment,
		'',
		'varying vec2 vUv;',
		'',
		'void main() {',
		'',
		'	gl_FragColor = texture2D( tDiffuse, vUv );',
		'',
		'	// tone mapping',
		'',
		'	#ifdef LINEAR_TONE_MAPPING',
		'		gl_FragColor.rgb = LinearToneMapping( gl_FragColor.rgb );',
		'	#elif defined( REINHARD_TONE_MAPPING )',
		'		gl_FragColor.rgb = ReinhardToneMapping( gl_FragColor.rgb );',
		'	#elif defined( CINEON_TONE_MAPPING )',
		'		gl_FragColor.rgb = OptimizedCineonToneMapping( gl_FragColor.rgb );',
		'	#elif defined( ACES_FILMIC_TONE_MAPPING )',
		'		gl_FragColor.rgb = ACESFilmicToneMapping( gl_FragColor.rgb );',
		'	#elif defined( AGX_TONE_MAPPING )',
		'		gl_FragColor.rgb = AgXToneMapping( gl_FragColor.rgb );',
		'	#elif defined( NEUTRAL_TONE_MAPPING )',
		'		gl_FragColor.rgb = NeutralToneMapping( gl_FragColor.rgb );',
		'	#endif',
		'',
		'	// color space',
		'',
		'	#ifdef SRGB_TRANSFER',
		'		gl_FragColor = sRGBTransferOETF( gl_FragColor );',
		'	#endif',
		'',
		'}'
	].join('\n');

	public static function getShader():ShaderMaterial {
		return new ShaderMaterial({
			uniforms: uniforms,
			vertexShader: vertexShader,
			fragmentShader: fragmentShader
		});
	}
}