package three.jsm.shaders;

import three.Vector2;

class FXAAShader {

    static var name:String = 'FXAAShader';

    static var uniforms:Map<String, Dynamic> = {
        'tDiffuse': { value: null },
        'resolution': { value: new Vector2( 1 / 1024, 1 / 512 ) }
    };

    static var vertexShader:String = `
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    `;

    static var fragmentShader:String = `
        precision highp float;

        uniform sampler2D tDiffuse;
        uniform vec2 resolution;
        varying vec2 vUv;

        // FXAA 3.11 implementation by NVIDIA, ported to WebGL by Agost Biro (biro@archilogic.com)

        // ... (rest of the fragment shader code)

        void main() {
            gl_FragColor = FxaaPixelShader(
                vUv,
                tDiffuse,
                resolution,
                0.2, // [0,1] contrast needed, otherwise early discard
                1. / 0.2
            );
        }
    `;

    // ... (rest of the class)
}