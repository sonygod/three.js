import js.Browser.window;
import js.html.CanvasElement;
import js.html.Document;
import js.html.HtmlElement;
import js.html.HtmlImageElement;
import js.html.ImageElement;
import js.html.Window;
import js.lib.WebGLRenderingContext;
import js.typed_array.Float32Array;
import js.typed_array.Uint8Array;

class Main {
    static function main() {
        var canvas = window.document.getElementById("canvas") as CanvasElement;
        var gl = canvas.getContext("webgl") as WebGLRenderingContext;

        if (gl == null) {
            trace("WebGL not supported, aborting");
            return;
        }

        var vertCode = "attribute vec2 position; void main(void) { gl_Position = vec4(position, 0.0, 1.0); }";
        var fragCode = "void main(void) { gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0); }";

        var vertShader = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertShader, vertCode);
        gl.compileShader(vertShader);

        var fragShader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragShader, fragCode);
        gl.compileShader(fragShader);

        var shaderProgram = gl.createProgram();
        gl.attachShader(shaderProgram, vertShader);
        gl.attachShader(shaderProgram, fragShader);
        gl.linkProgram(shaderProgram);

        gl.useProgram(shaderProgram);

        var buffer = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([0.0, 0.0, 64.0, 0.0, 0.0, 64.0]), gl.STATIC_DRAW);

        var posAttrib = gl.getAttribLocation(shaderProgram, "position");
        gl.vertexAttribPointer(posAttrib, 2, gl.FLOAT, false, 0, 0);
        gl.enableVertexAttribArray(posAttrib);

        gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.drawArrays(gl.TRIANGLES, 0, 3);
    }
}

Main.main();