/**
 * Exposure shader
 */

class ExposureShader {

    static var name:String = 'ExposureShader';

    static var uniforms:Map<String, Dynamic> = {

        'tDiffuse': { value: null },
        'exposure': { value: 1.0 }

    };

    static var vertexShader:String = `

        varying vec2 vUv;

        void main() {

            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

        }`;

    static var fragmentShader:String = `

        uniform float exposure;

        uniform sampler2D tDiffuse;

        varying vec2 vUv;

        void main() {

            gl_FragColor = texture2D( tDiffuse, vUv );
            gl_FragColor.rgb *= exposure;

        }`;

}