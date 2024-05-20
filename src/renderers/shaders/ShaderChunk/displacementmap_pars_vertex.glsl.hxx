import js.Browser;
import js.Lib.glMatrix;

class Main {
    static function main() {
        var canvas = Browser.document.getElementById("canvas");
        var gl = canvas.getContext("webgl");

        var vertexShaderSource = /* glsl */`
            attribute vec4 a_position;
            void main() {
                gl_Position = a_position;
            }
        `;

        var fragmentShaderSource = /* glsl */`
            void main() {
                gl_FragColor = vec4(1, 0, 0, 1);
            }
        `;

        var vertexShader = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertexShader, vertexShaderSource);
        gl.compileShader(vertexShader);

        var fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragmentShader, fragmentShaderSource);
        gl.compileShader(fragmentShader);

        var shaderProgram = gl.createProgram();
        gl.attachShader(shaderProgram, vertexShader);
        gl.attachShader(shaderProgram, fragmentShader);
        gl.linkProgram(shaderProgram);
        gl.useProgram(shaderProgram);

        var positionLocation = gl.getAttribLocation(shaderProgram, "a_position");
        var positionBuffer = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
            0, 0,
            0, 0.5,
            0.7, 0,
        ]), gl.STATIC_DRAW);

        gl.enableVertexAttribArray(positionLocation);
        gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);

        gl.drawArrays(gl.TRIANGLES, 0, 3);
    }
}