import js.Browser;
import js.html.WebGLRenderingContext;

class Main {
    static function main() {
        var canvas = Browser.document.createElement("canvas");
        var gl = cast canvas.getContext("webgl");

        var vertexShaderSource = /* glsl */`
        attribute vec4 a_position;
        void main() {
            gl_Position = a_position;
        }
        `;

        var fragmentShaderSource = /* glsl */`
        precision mediump float;
        uniform vec4 u_color;
        void main() {
            gl_FragColor = u_color;
        }
        `;

        var vertexShader = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertexShader, vertexShaderSource);
        gl.compileShader(vertexShader);

        var fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragmentShader, fragmentShaderSource);
        gl.compileShader(fragmentShader);

        var program = gl.createProgram();
        gl.attachShader(program, vertexShader);
        gl.attachShader(program, fragmentShader);
        gl.linkProgram(program);

        gl.useProgram(program);

        var positionLocation = gl.getAttribLocation(program, "a_position");
        var colorLocation = gl.getUniformLocation(program, "u_color");

        // ...
    }
}