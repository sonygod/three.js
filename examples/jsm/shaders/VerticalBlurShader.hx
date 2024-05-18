package three.js.examples.javascript.shaders;

import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

/**
 * Two pass Gaussian blur filter (horizontal and vertical blur shaders)
 * - see http://www.cake23.de/traveling-wavefronts-lit-up.html
 *
 * - 9 samples per pass
 * - standard deviation 2.7
 * - "h" and "v" parameters should be set to "1 / width" and "1 / height"
 */
class VerticalBlurShader {
    public static var shader:Shader;

    public static function init() {
        shader = new Shader();

        shader.glFragmentSource = '
            uniform sampler2D tDiffuse;
            uniform float v;

            varying vec2 vUv;

            void main() {
                vec4 sum = vec4(0.0);

                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 4.0 * v)) * 0.051;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 3.0 * v)) * 0.0918;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 2.0 * v)) * 0.12245;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 1.0 * v)) * 0.1531;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y)) * 0.1633;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 1.0 * v)) * 0.1531;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 2.0 * v)) * 0.12245;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 3.0 * v)) * 0.0918;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 4.0 * v)) * 0.051;

                gl_FragColor = sum;
            }';

        shader.glVertexSource = '
            varying vec2 vUv;

            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }';

        shader.data.tDiffuse.input = new ShaderInput("tDiffuse");
        shader.data.v.value = [1.0 / 512.0];
    }
}