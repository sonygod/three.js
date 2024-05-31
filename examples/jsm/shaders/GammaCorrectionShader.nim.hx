package three.examples.shaders;

import js.html.webgl.WebGLUniformLocation;
import three.js.UniformsUtils;
import three.js.ShaderLib;
import three.js.ShaderMaterial;
import three.js.Uniforms;
import three.js.Shader;

class GammaCorrectionShader {

	public static var name:String = 'GammaCorrectionShader';

	public static var uniforms:Uniforms = UniformsUtils.merge([
		ShaderLib.common.uniforms,
		{
			tDiffuse: { value: null }
		}
	]);

	public static var vertexShader:String = [
		"varying vec2 vUv;",
		"void main() {",
		"	vUv = uv;",
		"	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );",
		"}"
	].join("\n");

	public static var fragmentShader:String = [
		"uniform sampler2D tDiffuse;",
		"varying vec2 vUv;",
		"void main() {",
		"	vec4 tex = texture2D( tDiffuse, vUv );",
		"	gl_FragColor = sRGBTransferOETF( tex );",
		"}"
	].join("\n");

	public static function build():ShaderMaterial {
		var material = new ShaderMaterial({
			uniforms: uniforms,
			vertexShader: vertexShader,
			fragmentShader: fragmentShader
		});
		material.name = name;
		return material;
	}
}