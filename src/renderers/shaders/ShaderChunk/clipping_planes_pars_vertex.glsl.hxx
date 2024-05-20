import js.Browser;
import js.html.WebGLRenderingContext;
import js.html.WebGLProgram;
import js.html.WebGLShader;

class Main {
    static function main() {
        var canvas = Browser.document.getElementById("canvas");
        var gl = cast canvas.getContext("webgl");

        var vertexShaderSource = /* glsl */`
            #if NUM_CLIPPING_PLANES > 0
                varying vec3 vClipPosition;
            #endif
        `;

        var vertexShader = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertexShader, vertexShaderSource);
        gl.compileShader(vertexShader);

        if (!gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS)) {
            trace('Failed to compile vertex shader: ${gl.getShaderInfoLog(vertexShader)}');
            return;
        }

        // 创建和链接程序，然后使用程序，然后绘制
        // ...
    }
}