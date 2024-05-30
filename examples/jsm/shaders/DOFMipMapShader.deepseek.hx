package three.js.examples.jsm.shaders;

import js.Browser.window;

class DOFMipMapShader {

    static var name:String = 'DOFMipMapShader';

    static var uniforms:Map<String, Dynamic> = {

        'tColor': { value: null },
        'tDepth': { value: null },
        'focus': { value: 1.0 },
        'maxblur': { value: 1.0 }

    };

    static var vertexShader:String = `

        varying vec2 vUv;

        void main() {

            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

        }`;

    static var fragmentShader:String = `

        uniform float focus;
        uniform float maxblur;

        uniform sampler2D tColor;
        uniform sampler2D tDepth;

        varying vec2 vUv;

        void main() {

            vec4 depth = texture2D( tDepth, vUv );

            float factor = depth.x - focus;

            vec4 col = texture2D( tColor, vUv, 2.0 * maxblur * abs( focus - depth.x ) );

            gl_FragColor = col;
            gl_FragColor.a = 1.0;

        }`;

}