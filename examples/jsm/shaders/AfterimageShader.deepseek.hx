package three.js.examples.jsm.shaders;

import three.js.ShaderMaterial;
import three.js.Uniform;

class AfterimageShader {

    static var name:String = 'AfterimageShader';

    static var uniforms:Map<String, Uniform> = {
        'damp': new Uniform(0.96),
        'tOld': new Uniform(null),
        'tNew': new Uniform(null)
    };

    static var vertexShader:String = `
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }`;

    static var fragmentShader:String = `
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
        }`;

    static function createMaterial():ShaderMaterial {
        return new ShaderMaterial({
            name: name,
            uniforms: uniforms,
            vertexShader: vertexShader,
            fragmentShader: fragmentShader
        });
    }
}