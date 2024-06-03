package three.js.examples.jsm.shaders;

import three.js.core.Uniform;

class BlendShader {

    public static var name:String = 'BlendShader';

    public static var uniforms:haxe.ds.StringMap<Uniform> = new haxe.ds.StringMap<Uniform>();

    public function new() {
        uniforms["tDiffuse1"] = new Uniform(null);
        uniforms["tDiffuse2"] = new Uniform(null);
        uniforms["mixRatio"] = new Uniform(0.5);
        uniforms["opacity"] = new Uniform(1.0);
    }

    public static var vertexShader:String = """
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    """;

    public static var fragmentShader:String = """
        uniform float opacity;
        uniform float mixRatio;

        uniform sampler2D tDiffuse1;
        uniform sampler2D tDiffuse2;

        varying vec2 vUv;

        void main() {
            vec4 texel1 = texture2D( tDiffuse1, vUv );
            vec4 texel2 = texture2D( tDiffuse2, vUv );
            gl_FragColor = opacity * mix( texel1, texel2, mixRatio );
        }
    """;
}