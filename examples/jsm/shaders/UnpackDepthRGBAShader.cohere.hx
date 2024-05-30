package;

import js.WebGL.WebGLProgram;
import js.WebGL.WebGLShader;

class UnpackDepthRGBAShader {
	public var name: String = 'UnpackDepthRGBAShader';
	public var uniforms: { [key: String]: { value: Dynamic; } } = {
		'tDiffuse': { value: null },
		'opacity': { value: 1.0 }
	};
	public var vertexShader: String = '''
		varying vec2 vUv;

		void main() {

			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}
	''';
	public var fragmentShader: String = '''
		uniform float opacity;
		uniform sampler2D tDiffuse;
		varying vec2 vUv;

		#include <packing>

		void main() {

			float depth = 1.0 - unpackRGBAToDepth( texture2D( tDiffuse, vUv ) );
			gl_FragColor = vec4( vec3( depth ), opacity );

		}
	''';

	public function new(): Void {

	}
}