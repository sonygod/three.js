import haxe.io.Bytes;
import js.Browser;
import js.lib.Math;

@:enum(Int)
class ShaderType {
    const Vertex = 0;
    const Fragment = 1;
}

class ShaderNode {
    public var name: String;
    public var type: ShaderType;
    public var source: Bytes;

    public function new(name: String, type: ShaderType, source: Bytes) {
        this.name = name;
        this.type = type;
        this.source = source;
    }
}

class BRDF_Sheen {
    public static function D_Charlie(roughness: Float, dotNH: Float): Float {
        var alpha = Math.pow(roughness, 2.0);
        var invAlpha = 1.0 / alpha;
        var cos2h = Math.pow(dotNH, 2.0);
        var sin2h = Math.max(1.0 - cos2h, 0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16
        return (2.0 + invAlpha) * Math.pow(sin2h, invAlpha * 0.5) / (2.0 * Math.PI);
    }

    public static function V_Neubelt(dotNV: Float, dotNL: Float): Float {
        return 1.0 / (4.0 * (dotNL + dotNV - dotNL * dotNV));
    }

    public static function BRDF(lightDirection: Float) -> Float {
        var halfDir = (lightDirection + positionViewDirection) / Math.sqrt(Math.pow(lightDirection, 2.0) + Math.pow(positionViewDirection, 2.0) + 1e-20);

        var dotNL = Math.clamp(transformedNormalView.dot(lightDirection), 0.0, 1.0);
        var dotNV = Math.clamp(transformedNormalView.dot(positionViewDirection), 0.0, 1.0);
        var dotNH = Math.clamp(transformedNormalView.dot(halfDir), 0.0, 1.0);

        var D = D_Charlie(sheenRoughness, dotNH);
        var V = V_Neubelt(dotNV, dotNL);

        return sheen * D * V;
    }
}

class Main {
    static function main() {
        #if js
        var gl = Browser.createWebGLContext(Browser.window.document.getElementById("canvas"));
        if (gl == null) {
            trace("Failed to create WebGL context.");
            return;
        }

        var shaderSource = "#version 300 es\n" +
            "in vec3 a_position;\n" +
            "void main() {\n" +
            "  gl_Position = vec4(a_position, 1.0);\n" +
            "}\n";

        var vertexShader = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertexShader, shaderSource);
        gl.compileShader(vertexShader);

        if (!gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS)) {
            trace("Vertex shader compilation failed:\n" + gl.getShaderInfoLog(vertexShader));
            return;
        }

        var fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragmentShader, "#version 300 es\n" +
            "precision mediump float;\n" +
            "out vec4 f_color;\n" +
            "void main() {\n" +
            "  f_color = vec4(0.0, 0.5, 1.0, 1.0);\n" +
            "}\n");
        gl.compileShader(fragmentShader);

        if (!gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS)) {
            trace("Fragment shader compilation failed:\n" + gl.getShaderInfoLog(fragmentShader));
            return;
        }

        var program = gl.createProgram();
        gl.attachShader(program, vertexShader);
        gl.attachShader(program, fragmentShader);
        gl.linkProgram(program);

        if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
            trace("Shader program linking failed: " + gl.getProgramInfoLog(program));
            return;
        }

        gl.useProgram(program);

        var vertices = [0.0, 0.5, 0.0, -0.5, -0.5, 0.0, 0.5, -0.5, 0.0];
        var vertexBuffer = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
        gl.bufferData(gl.ARRAY_BUFFER, new js.Browser.Float32Array(vertices), gl.STATIC_DRAW);

        var a_position = gl.getAttribLocation(program, "a_position");
        gl.vertexAttribPointer(a_position, 3, gl.FLOAT, false, 0, 0);
        gl.enableVertexAttribArray(a_position);

        gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.drawArrays(gl.TRIANGLES, 0, 3);
        #end
    }
}