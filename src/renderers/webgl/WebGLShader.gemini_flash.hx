class WebGLShader {

	public static function create(gl: WebGLRenderingContext, type: Int, string: String): WebGLShader {
		var shader = gl.createShader(type);
		gl.shaderSource(shader, string);
		gl.compileShader(shader);
		return shader;
	}

}