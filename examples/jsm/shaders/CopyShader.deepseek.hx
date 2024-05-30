package three.js.examples.jsm.shaders;

class CopyShader {

    static var name:String = 'CopyShader';

    static var uniforms:Map<String, Dynamic> = {

        'tDiffuse': { value: null },
        'opacity': { value: 1.0 }

    };

    static var vertexShader:String = '

        varying vec2 vUv;

        void main() {

            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

        }';

    static var fragmentShader:String = '

        uniform float opacity;

        uniform sampler2D tDiffuse;

        varying vec2 vUv;

        void main() {

            vec4 texel = texture2D( tDiffuse, vUv );
            gl_FragColor = opacity * texel;

        }';

}