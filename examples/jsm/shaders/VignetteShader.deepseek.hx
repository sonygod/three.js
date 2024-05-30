package three.js.examples.jsm.shaders;

class VignetteShader {

    static var name:String = 'VignetteShader';

    static var uniforms:Map<String, Dynamic> = {

        'tDiffuse': { value: null },
        'offset': { value: 1.0 },
        'darkness': { value: 1.0 }

    };

    static var vertexShader:String = `

        varying vec2 vUv;

        void main() {

            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

        }`;

    static var fragmentShader:String = `

        uniform float offset;
        uniform float darkness;

        uniform sampler2D tDiffuse;

        varying vec2 vUv;

        void main() {

            // Eskil's vignette

            vec4 texel = texture2D( tDiffuse, vUv );
            vec2 uv = ( vUv - vec2( 0.5 ) ) * vec2( offset );
            gl_FragColor = vec4( mix( texel.rgb, vec3( 1.0 - darkness ), dot( uv, uv ) ), texel.a );

        }`;

}