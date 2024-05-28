package three.js.src.renderers.webgl;

class WebGLShader {
  public function new(gl: WebGLRenderingContext, type: GLenum, string: String) {
    var shader = gl.createShader(type);
    gl.shaderSource(shader, string);
    gl.compileShader(shader);
    this.shader = shader;
  }

  public var shader: WebGLShader;
}