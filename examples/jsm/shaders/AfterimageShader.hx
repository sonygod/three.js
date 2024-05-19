package three.js.examples.jm.shaders;

import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderPrecision;

/**
 * Afterimage shader
 * I created this effect inspired by a demo on codepen:
 * https://codepen.io/brunoimbrizi/pen/MoRJaN?page=1&
 */

class AfterimageShader {
    public static var NAME:String = 'AfterimageShader';

    private var shader:Shader;

    public function new() {
        shader = new Shader();

        shader.vertex = '
            varying vec2 vUv;

            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }
        ';

        shader.fragment = '
            uniform float damp;
            uniform sampler2D tOld;
            uniform sampler2D tNew;

            varying vec2 vUv;

            vec4 when_gt(vec4 x, float y) {
                return max(sign(x - y), 0.0);
            }

            void main() {
                vec4 texelOld = texture2D(tOld, vUv);
                vec4 texelNew = texture2D(tNew, vUv);

                texelOld *= damp * when_gt(texelOld, 0.1);

                gl_FragColor = max(texelNew, texelOld);
            }
        ';

        shader.data.damp.value = [0.96];
        shader.data.tOld.value = null;
        shader.data.tNew.value = null;
    }
}