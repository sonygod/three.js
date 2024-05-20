import js.Browser;
import js.webgl.WebGL;
import js.webgl.WebGLProgram;
import js.webgl.WebGLShader;
import js.webgl.WebGLRenderingContext;

class ShaderChunk {
    static var gl:WebGLRenderingContext;

    static function init(context:WebGLRenderingContext) {
        gl = context;
    }

    static function compileShader(type:Int, source:String):WebGLShader {
        var shader:WebGLShader = gl.createShader(type);
        gl.shaderSource(shader, source);
        gl.compileShader(shader);
        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
            trace('An error occurred compiling the shaders: ' + gl.getShaderInfoLog(shader));
            return null;
        }
        return shader;
    }

    static function createProgram(vertexShader:WebGLShader, fragmentShader:WebGLShader):WebGLProgram {
        var program:WebGLProgram = gl.createProgram();
        gl.attachShader(program, vertexShader);
        gl.attachShader(program, fragmentShader);
        gl.linkProgram(program);
        if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
            trace('Unable to initialize the shader program: ' + gl.getProgramInfoLog(program));
            return null;
        }
        return program;
    }
}