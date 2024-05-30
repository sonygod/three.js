import js.Browser.window;
import js.WebGL.RenderingContext2D.prototype.*;

class Main {
    static function main() {
        var canvas = window.document.getElementById("canvas");
        var gl = canvas.getContextWebGL();
        if (gl == null) {
            trace("WebGL unsupported");
            return;
        }

        var vertexShaderSource = "#version 300 es
            in vec2 vertexPosition;
            void main() {
                gl_Position = vec4(vertexPosition, 0.0, 1.0);
            }";

        var fragmentShaderSource = "#version 300 es
            precision highp float;
            out vec4 fragColor;
            void main() {
                fragColor = vec4(0.0, 1.0, 0.0, 1.0);
            }";

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

        var vertices = [0.0, 0.5, -0.5, -0.5, 0.5, -0.5];
        var vertexBuffer = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);

        var vao = gl.createVertexArray();
        gl.bindVertexArray(vao);
        gl.enableVertexAttribArray(0);
        gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);

        gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.useProgram(program);
        gl.bindVertexArray(vao);
        gl.drawArrays(gl.TRIANGLES, 0, 3);
    }
}