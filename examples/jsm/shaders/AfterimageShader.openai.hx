package three.js.examples.jsm.shaders;

import three.shader.Shader;

class AfterimageShader extends Shader {
    public var name(get, never):String = 'AfterimageShader';

    public var uniforms = {
        damp: { value: 0.96 },
        tOld: { value: null },
        tNew: { value: null }
    };

    public var vertexShader:String = "
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }";

    public var fragmentShader:String = "
        uniform float damp;
        uniform sampler2D tOld;
        uniform sampler2D tNew;
        varying vec2 vUv;

        vec4 when_gt( vec4 x, float y ) {
            return max( sign( x - y ), 0.0 );
        }

        void main() {
            vec4 texelOld = texture2D( tOld, vUv );
            vec4 texelNew = texture2D( tNew, vUv );
            texelOld *= damp * when_gt( texelOld, 0.1 );
            gl_FragColor = max(texelNew, texelOld);
        }";
}