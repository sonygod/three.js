package renderers.webgl;

import js.html.webgl.RenderingContext;
import js.html.webgl.Shader;

class WebGLShader {
    private var shader:Shader;

    public function new(gl:RenderingContext, type:Int, string:String) {
        shader = gl.createShader(type);
        gl.shaderSource(shader, string);
        gl.compileShader(shader);
    }

    public function getShader():Shader {
        return shader;
    }
}