package three.examples.shaders;

import js.Lib;

/**
 * Simple test shader
 */
class BasicShader {

	public static var name:String = 'BasicShader';

	public static var uniforms:Dynamic = {};

	public static var vertexShader:String = '
		void main() {
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
		}';

	public static var fragmentShader:String = '
		void main() {
			gl_FragColor = vec4( 1.0, 0.0, 0.0, 0.5 );
		}';

	public static function main() {
		Lib.export('BasicShader', BasicShader);
	}
}