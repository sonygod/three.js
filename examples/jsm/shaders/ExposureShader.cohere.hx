package;

import js.WebGL.WebGLProgram;
import js.WebGL.WebGLRenderingContext;

class ExposureShader {
	public var name: String = "ExposureShader";
	public var uniforms: { [key: String]: { value: Dynamic } } = {
		'tDiffuse': { value: null },
		'exposure': { value: 1.0 }
	};
	public var vertexShader: String =
		"varying vec2 vUv; \n" +
		"void main() { \n" +
		"vUv = uv; \n" +
		"gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); \n" +
		"}";
	public var fragmentShader: String =
		"uniform float exposure; \n" +
		"uniform sampler2D tDiffuse; \n" +
		"varying vec2 vUv; \n" +
		"void main() { \n" +
		"gl_FragColor = texture2D(tDiffuse, vUv); \n" +
		"gl_FragColor.rgb *= exposure; \n" +
		"}";

	public function new(): Void {

	}

	public function buildProgram(gl: WebGLRenderingContext): WebGLProgram {
		var program = gl.createProgram();
		var vs = compileShader(gl, vertexShader, WebGLRenderingContext.VERTEX_SHADER);
		var fs = compileShader(gl, fragmentShader, WebGLRenderingContext.FRAGMENT_SHADER);
		gl.attachShader(program, vs);
		gl.attachShader(program, fs);
		gl.linkProgram(program);
		return program;
	}

	private function compileShader(gl: WebGLRenderingContext, shaderSource: String, shaderType: Int): Int {
		var shader = gl.createShader(shaderType);
		gl.shaderSource(shader, shaderSource);
		gl.compileShader(shader);
		return shader;
	}
}