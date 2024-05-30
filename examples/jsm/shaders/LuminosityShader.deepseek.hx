package three.js.examples.jsm.shaders;

import three.js.examples.jsm.shaders.common;

class LuminosityShader {

    static var name:String = 'LuminosityShader';

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

        #include <common>

        uniform sampler2D tDiffuse;

        varying vec2 vUv;

        void main() {

            vec4 texel = texture2D( tDiffuse, vUv );

            float l = luminance( texel.rgb );

            gl_FragColor = vec4( l, l, l, texel.w );

        }`;

}