package three.js.examples.jvm.shaders;

import three.js.shaders.Shader;

/**
 * Gamma Correction Shader
 * http://en.wikipedia.org/wiki/gamma_correction
 */

class GammaCorrectionShader extends Shader {

    public function new() {
        super();
        this.name = "GammaCorrectionShader";
        this.uniforms = {
            tDiffuse: { value: null }
        };
        this.vertexShader = '
            varying vec2 vUv;

            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }
        ';
        this.fragmentShader = '
            uniform sampler2D tDiffuse;
            varying vec2 vUv;

            void main() {
                vec4 tex = texture2D( tDiffuse, vUv );
                gl_FragColor = sRGBTransferOETF( tex );
            }
        ';
    }
}