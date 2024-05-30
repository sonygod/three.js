package three.js.examples.jsm.shaders;

class BlendShader {
    public var name:String = 'BlendShader';

    public var uniforms: {
        tDiffuse1: { value:Null<Dynamic> },
        tDiffuse2: { value:Null<Dynamic> },
        mixRatio: { value:Float = 0.5 },
        opacity: { value:Float = 1.0 }
    }

    public var vertexShader:String = "
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    ";

    public var fragmentShader:String = "
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
    ";
}