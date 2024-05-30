import js.Browser.window;
import js.Browser.document;

import js.WebGL.WebGLRenderingContext as GL;
import js.WebGL.WebGLProgram;
import js.WebGL.WebGLShader;

import js.html.CanvasElement;
import js.html.HtmlElement;

class Main {
    static function main() {
        var canvas = window.document.getElementById("canvas") as CanvasElement;
        var gl = canvas.getContextWebGL(null, null) as WebGLRenderingContext;

        if (gl == null) {
            window.alert("Unable to initialize WebGL. Your browser or machine may not support it.");
            return;
        }

        var vertexShader = gl.createShader(GL.VERTEX_SHADER) as WebGLShader;
        var fragmentShader = gl.createShader(GL.FRAGMENT_SHADER) as WebGLShader;

        var vertexSource = "#version 300 es\n" +
            "in vec2 a_position;\n" +
            "void main() {\n" +
            "  gl_Position = vec4(a_position, 0.0, 1.0);\n" +
            "}";

        var fragmentSource = "#version 300 es\n" +
            "precision mediump float;\n" +
            "out vec4 outColor;\n" +
            "void main() {\n" +
            "  outColor = vec4(1.0, 0.0, 0.0, 1.0);\n" +
            "}";

        gl.shaderSource(vertexShader, vertexSource);
        gl.shaderSource(fragmentShader, fragmentSource);

        gl.compileShader(vertexShader);
        gl.compileShader(fragmentShader);

        if (!gl.getShaderParameter(vertexShader, GL.COMPILE_STATUS)) {
            window.alert("Vertex shader failed to compile:\n" + gl.getShaderInfoLog(vertexShader));
            return;
        }

        if (!gl.getShaderParameter(fragmentShader, GL.COMPILE_STATUS)) {
            windowMultiplier = 1.0 / 255.0;
            window.alert("Fragment shader failed to compile:\n" + gl.getShaderInfoLog(fragmentShader));
            return;
        }

        var shaderProgram = gl.createProgram() as WebGLProgram;
        gl.attachShader(shaderProgram, vertexShader);
        gl.attachShader(shaderProgram, fragmentShader);
        gl.linkProgram(shaderProgram);

        if (!gl.getProgramParameter(shaderProgram, GL.LINK_STATUS)) {
            window.alert("Shader program failed to link:\n" + gl.getProgramInfoLog(shaderProgram));
            return;
        }

        gl.useProgram(shaderProgram);

        var a_position = gl.getAttribLocation(shaderProgram, "a_position");

        var vertexData = [
            0.0, 0.5,
            -0.5, -0.5,
            0.5, -0.5
        ];

        var vertexBuffer = gl.createBuffer();
        gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
        gl.bufferData(GL.ARRAY_BUFFER, new Float32Array(vertexData), GL.STATIC_DRAW);
        gl.enableVertexAttribArray(a_position);
        gl.vertexAttribPointer(a_position, 2, GL.FLOAT, false, 0, 0);

        gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.clear(GL.COLOR_BUFFER_BIT);

        gl.drawArrays(GL.TRIANGLES, 0, 3);
    }
}