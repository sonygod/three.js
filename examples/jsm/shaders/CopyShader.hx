package three.js.examples.jm.shaders;

import openfl.display.Shader;

class CopyShader {
    public static var NAME:String = 'CopyShader';

    public static var uniforms = {
        tDiffuse: { value: null },
        opacity: { value: 1.0 }
    };

    public static var vertexShader:String = "
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    ";

    public static var fragmentShader:String = "
        uniform float opacity;
        uniform sampler2D tDiffuse;

        varying vec2 vUv;

        void main() {
            vec4 texel = texture2D( tDiffuse, vUv );
            gl_FragColor = opacity * texel;
        }
    ";

    public function new() {}

    public static function createShader():Shader {
        var shader:Shader = new Shader();
        shader.vertexShader = vertexShader;
        shader.fragmentShader = fragmentShader;
        shader.uniforms = uniforms;
        return shader;
    }
}