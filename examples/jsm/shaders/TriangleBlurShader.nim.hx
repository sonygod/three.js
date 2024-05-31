import three.js.Vector2;

/**
 * Triangle blur shader
 * based on glfx.js triangle blur shader
 * https://github.com/evanw/glfx.js
 *
 * A basic blur filter, which convolves the image with a
 * pyramid filter. The pyramid filter is separable and is applied as two
 * perpendicular triangle filters.
 */

class TriangleBlurShader {

	public static var name:String = 'TriangleBlurShader';

	public static var uniforms:Dynamic = {

		'texture': { value: null },
		'delta': { value: new Vector2( 1, 1 ) }

	};

	public static var vertexShader:String =
		"varying vec2 vUv;\n\n" +
		"void main() {\n" +
		"	vUv = uv;\n" +
		"	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n" +
		"}\n";

	public static var fragmentShader:String =
		"#include <common>\n\n" +
		"#define ITERATIONS 10.0\n\n" +
		"uniform sampler2D texture;\n" +
		"uniform vec2 delta;\n\n" +
		"varying vec2 vUv;\n\n" +
		"void main() {\n" +
		"	vec4 color = vec4( 0.0 );\n\n" +
		"	float total = 0.0;\n\n" +
		"	// randomize the lookup values to hide the fixed number of samples\n" +
		"	float offset = rand( vUv );\n\n" +
		"	for ( float t = -ITERATIONS; t <= ITERATIONS; t ++ ) {\n" +
		"		float percent = ( t + offset - 0.5 ) / ITERATIONS;\n" +
		"		float weight = 1.0 - abs( percent );\n" +
		"		color += texture2D( texture, vUv + delta * percent ) * weight;\n" +
		"		total += weight;\n" +
		"	}\n\n" +
		"	gl_FragColor = color / total;\n" +
		"}\n";

}


Please note that Haxe does not have a direct equivalent to JavaScript's `export` statement. If you want to make `TriangleBlurShader` available to other modules, you can use Haxe's `package` and `public` keywords. For example:


package three.js.examples.jsm.shaders;

public class TriangleBlurShader {
    ...
}