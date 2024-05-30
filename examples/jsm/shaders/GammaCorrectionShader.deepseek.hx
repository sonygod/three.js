/**
 * Gamma Correction Shader
 * http://en.wikipedia.org/wiki/gamma_correction
 */

class GammaCorrectionShader {

    static var name:String = 'GammaCorrectionShader';

    static var uniforms:Map<String, Dynamic> = {

        'tDiffuse': { value: null }

    };

    static var vertexShader:String = `

        varying vec2 vUv;

        void main() {

            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

        }`;

    static var fragmentShader:String = `

        uniform sampler2D tDiffuse;

        varying vec2 vUv;

        void main() {

            vec4 tex = texture2D( tDiffuse, vUv );

            gl_FragColor = sRGBTransferOETF( tex );

        }`;

}