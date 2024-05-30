package three.js.examples.jsm.shaders;

import three.js.Three;

class FilmShader {
    public static var NAME:String = 'FilmShader';

    public static var uniforms:Uniforms = {
        tDiffuse: { value: null },
        time: { value: 0.0 },
        intensity: { value: 0.5 },
        grayscale: { value: false }
    };

    public static var vertexShader:String = `
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    `;

    public static var fragmentShader:String = `
        #include <common>

        uniform float intensity;
        uniform bool grayscale;
        uniform float time;
        uniform sampler2D tDiffuse;

        varying vec2 vUv;

        void main() {
            vec4 base = texture2D( tDiffuse, vUv );
            float noise = rand( fract( vUv + time ) );
            vec3 color = base.rgb + base.rgb * clamp( 0.1 + noise, 0.0, 1.0 );
            color = mix( base.rgb, color, intensity );
            if ( grayscale ) {
                color = vec3( luminance( color ) ); // assuming linear-srgb
            }
            gl_FragColor = vec4( color, base.a );
        }
    `;
}