import js.Browser;
import js.html.WebGLRenderingContext;
import js.html.WebGLProgram;
import js.html.WebGLShader;

class ShaderLib {
    static var gl:WebGLRenderingContext;
    static var vertexShader:WebGLShader;
    static var fragmentShader:WebGLShader;
    static var program:WebGLProgram;

    static function init() {
        var canvas = Browser.document.getElementById("canvas");
        gl = cast canvas.getContext("webgl");

        vertexShader = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertexShader, vertex);
        gl.compileShader(vertexShader);

        fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragmentShader, fragment);
        gl.compileShader(fragmentShader);

        program = gl.createProgram();
        gl.attachShader(program, vertexShader);
        gl.attachShader(program, fragmentShader);
        gl.linkProgram(program);
    }

    static var vertex = /* glsl */`
    // Your vertex shader code here
    `;

    static var fragment = /* glsl */`
    // Your fragment shader code here
    `;
}