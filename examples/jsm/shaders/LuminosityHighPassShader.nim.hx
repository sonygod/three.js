import three.js.extras.core.Color;

/**
 * Luminosity
 * http://en.wikipedia.org/wiki/Luminosity
 */

class LuminosityHighPassShader {

	public static var name:String = 'LuminosityHighPassShader';

	public static var shaderID:String = 'luminosityHighPass';

	public static var uniforms:Dynamic = {

		'tDiffuse': { value: null },
		'luminosityThreshold': { value: 1.0 },
		'smoothWidth': { value: 1.0 },
		'defaultColor': { value: new Color( 0x000000 ) },
		'defaultOpacity': { value: 0.0 }

	};

	public static var vertexShader:String =

		'varying vec2 vUv;\n\n' +

		'void main() {\n' +

		'	vUv = uv;\n\n' +

		'	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n' +

		'}\n';

	public static var fragmentShader:String =

		'uniform sampler2D tDiffuse;\n' +
		'uniform vec3 defaultColor;\n' +
		'uniform float defaultOpacity;\n' +
		'uniform float luminosityThreshold;\n' +
		'uniform float smoothWidth;\n\n' +

		'varying vec2 vUv;\n\n' +

		'void main() {\n' +

		'	vec4 texel = texture2D( tDiffuse, vUv );\n\n' +

		'	vec3 luma = vec3( 0.299, 0.587, 0.114 );\n\n' +

		'	float v = dot( texel.xyz, luma );\n\n' +

		'	vec4 outputColor = vec4( defaultColor.rgb, defaultOpacity );\n\n' +

		'	float alpha = smoothstep( luminosityThreshold, luminosityThreshold + smoothWidth, v );\n\n' +

		'	gl_FragColor = mix( outputColor, texel, alpha );\n' +

		'}\n';

}