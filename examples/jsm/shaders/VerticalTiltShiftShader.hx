package three.js.examples.jsw.shaders;

import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class VerticalTiltShiftShader {
    public static var NAME:String = 'VerticalTiltShiftShader';

    private var shader:Shader;

    public function new() {
        shader = new Shader();

        var vertexShader:String = "
            varying vec2 vUv;

            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }
        ";

        var fragmentShader:String = "
            uniform sampler2D tDiffuse;
            uniform float v;
            uniform float r;

            varying vec2 vUv;

            void main() {
                vec4 sum = vec4(0.0);

                float vv = v * abs(r - vUv.y);

                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 4.0 * vv)) * 0.051;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 3.0 * vv)) * 0.0918;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 2.0 * vv)) * 0.12245;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 1.0 * vv)) * 0.1531;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y)) * 0.1633;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 1.0 * vv)) * 0.1531;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 2.0 * vv)) * 0.12245;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 3.0 * vv)) * 0.0918;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 4.0 * vv)) * 0.051;

                gl_FragColor = sum;
            }
        ";

        shader.glVertexShader = vertexShader;
        shader.glFragmentShader = fragmentShader;

        var tDiffuse:ShaderInput<BitmapData> = new ShaderInput<BitmapData>("tDiffuse");
        tDiffuse.value = null;

        var v:ShaderParameter<Float> = new ShaderParameter<Float>("v");
        v.value = [1.0 / 512.0];

        var r:ShaderParameter<Float> = new ShaderParameter<Float>("r");
        r.value = [0.35];

        shader.data.tDiffuse = tDiffuse;
        shader.data.v = v;
        shader.data.r = r;
    }

    public function getShader():Shader {
        return shader;
    }
}