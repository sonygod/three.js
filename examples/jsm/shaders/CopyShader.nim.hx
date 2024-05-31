package three.examples.jsm.shaders;

import js.lib.webgl.Uniform;
import three.js.UniformsUtils;
import three.js.ShaderLib;
import three.js.ShaderMaterial;
import three.js.Vector2;
import three.js.Vector3;
import three.js.Vector4;

class CopyShader {

	public static var name:String = 'CopyShader';

	public static var uniforms:Dynamic = {
		'tDiffuse': new Uniform(null),
		'opacity': new Uniform(1.0)
	};

	public static var vertexShader:String = 'varying vec2 vUv;\n\nvoid main() {\n\tvUv = uv;\n\tgl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n\n}';

	public static var fragmentShader:String = 'uniform float opacity;\n\nuniform sampler2D tDiffuse;\n\nvarying vec2 vUv;\n\nvoid main() {\n\tvec4 texel = texture2D( tDiffuse, vUv );\n\tgl_FragColor = opacity * texel;\n\n}';

	public static function build():ShaderMaterial {
		var material = new ShaderMaterial({
			uniforms: UniformsUtils.clone(uniforms),
			vertexShader: vertexShader,
			fragmentShader: fragmentShader
		});
		material.name = name;
		return material;
	}
}