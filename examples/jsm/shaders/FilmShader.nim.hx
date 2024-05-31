package three.examples.jsm.shaders;

import js.html.WebGLUniformLocation;
import three.js.UniformsUtils;
import three.js.ShaderLib;
import three.js.ShaderMaterial;
import three.js.UniformsLib;
import three.js.ShaderChunk;

class FilmShader {

	public static var name:String = 'FilmShader';

	public static var uniforms:Dynamic = {
		'tDiffuse': { value: null },
		'time': { value: 0.0 },
		'intensity': { value: 0.5 },
		'grayscale': { value: false }
	};

	public static var vertexShader:String = 'varying vec2 vUv;\n\nvoid main() {\n\tvUv = uv;\n\tgl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n\n}';

	public static var fragmentShader:String = '#include <common>\n\nuniform float intensity;\nuniform bool grayscale;\nuniform float time;\n\nuniform sampler2D tDiffuse;\n\nvarying vec2 vUv;\n\nvoid main() {\n\tvec4 base = texture2D( tDiffuse, vUv );\n\n\tfloat noise = rand( fract( vUv + time ) );\n\n\tvec3 color = base.rgb + base.rgb * clamp( 0.1 + noise, 0.0, 1.0 );\n\n\tcolor = mix( base.rgb, color, intensity );\n\n\tif ( grayscale ) {\n\t\tcolor = vec3( luminance( color ) ); // assuming linear-srgb\n\t}\n\n\tgl_FragColor = vec4( color, base.a );\n\n}';

	public static function getShader():ShaderMaterial {
		var uniforms:Dynamic = UniformsUtils.clone(uniforms);
		uniforms['tDiffuse'].value = ShaderLib.fog.uniforms['tDiffuse'].value;
		var material:ShaderMaterial = new ShaderMaterial({
			uniforms: uniforms,
			vertexShader: vertexShader,
			fragmentShader: fragmentShader
		});
		material.defines = ShaderLib.fog.defines;
		material.extensions = ShaderLib.fog.extensions;
		material.lights = ShaderLib.fog.lights;
		material.fog = ShaderLib.fog.fog;
		material.uniforms = UniformsUtils.merge([ShaderLib.fog.uniforms, material.uniforms]);
		material.vertexShader = ShaderChunk.replaceShaderChunk(material.vertexShader, '/* gl_Position */', ShaderLib.fog.vertexShader);
		material.fragmentShader = ShaderChunk.replaceShaderChunk(material.fragmentShader, '/* gl_FragColor */', ShaderLib.fog.fragmentShader);
		return material;
	}
}