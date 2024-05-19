package three.js.examples.jm.shaders;

import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

/**
 * RGB Shift Shader
 * Shifts red and blue channels from center in opposite directions
 * Ported from https://web.archive.org/web/20090820185047/http://kriss.cx/tom/2009/05/rgb-shift/
 * by Tom Butterworth / https://web.archive.org/web/20090810054752/http://kriss.cx/tom/
 *
 * amount: shift distance (1 is width of input)
 * angle: shift angle in radians
 */
class RGBShiftShader {
    public static var shader:Shader;

    public static function init() {
        shader = new Shader();
        shader.glFragmentSource = "
            uniform sampler2D tDiffuse;
            uniform float amount;
            uniform float angle;

            varying vec2 vUv;

            void main() {
                vec2 offset = amount * vec2( cos(angle), sin(angle));
                vec4 cr = texture2D(tDiffuse, vUv + offset);
                vec4 cga = texture2D(tDiffuse, vUv);
                vec4 cb = texture2D(tDiffuse, vUv - offset);
                gl_FragColor = vec4(cr.r, cga.g, cb.b, cga.a);
            }
        ";

        shader.glVertexSource = "
            varying vec2 vUv;

            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }
        ";

        shader.data.tDiffuse.input = new ShaderInput<ShaderParameter<File>>("tDiffuse");
        shader.data.amount.value = [0.005];
        shader.data.angle.value = [0.0];
    }
}