function webGLShader(gl: WebGLRenderer, type:Int, string:String):WebGLShader {
	var shader = gl.createShader(type);
	gl.shaderSource(shader, string);
	gl.compileShader(shader);
	return shader;
}

class WebGLShader {
	public var gl: WebGLRenderer;
	public var type: Int;
	public var string: String;

	public function new(gl: WebGLRenderer, type:Int, string:String) {
		this.gl = gl;
		this.type = type;
		this.string = string;
	}
}