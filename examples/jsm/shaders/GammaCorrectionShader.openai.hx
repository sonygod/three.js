package three.js.examples.jsm.shaders;

/**
 * Gamma Correction Shader
 * http://en.wikipedia.org/wiki/gamma_correction
 */

class GammaCorrectionShader {
    public var name:String = 'GammaCorrectionShader';

    public var uniforms:Uniforms = {
        tDiffuse: { value: null }
    };

    public var vertexShader:String = '
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    ';

    public var fragmentShader:String = '
        uniform sampler2D tDiffuse;

        varying vec2 vUv;

        void main() {
            vec4 tex = texture2D(tDiffuse, vUv);
            gl_FragColor = sRGBTransferOETF(tex);
        }
    ';
}