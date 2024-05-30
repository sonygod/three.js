package;

import js.WebGL.WebGLProgram;
import js.WebGL.WebGLRenderingContext;

class CopyShader {
	public var name: String = "CopyShader";

	public var uniforms: { [key: String]: { value: Dynamic } } = {
		'tDiffuse': { value: null },
		'opacity': { value: 1.0 }
	};

	public var vertexShader: String =
		"varying vec2 vUv;" +
		"void main() {" +
		"vUv = uv;" +
		"gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);" +
		"}";

	public var fragmentShader: String =
		"uniform float opacity;" +
		"uniform sampler2D tDiffuse;" +
		"varying vec2 vUv;" +
		"void main() {" +
		"vec4 texel = texture2D(tDiffuse, vUv);" +
		"gl_FragColor = opacity * texel;" +
		"}";

	public function new() {

	}
}

class Main {
	static public function main() {
		var shader = new CopyShader();
		// 使用 shader
	}
}