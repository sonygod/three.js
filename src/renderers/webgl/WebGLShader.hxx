class WebGLShader {

    public function new(gl:WebGLRenderingContext, type:Int, string:String) {

        var shader = gl.createShader(type);

        gl.shaderSource(shader, string);
        gl.compileShader(shader);

        return shader;

    }

}