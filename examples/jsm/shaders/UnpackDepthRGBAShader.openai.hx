package three.js.examples.jm.shaders;

import three.js.Three;

class UnpackDepthRGBAShader {
    public static var NAME:String = "UnpackDepthRGBAShader";

    public var uniforms:UnpackDepthRGBAShaderUniforms = {
        tDiffuse: { value: null },
        opacity: { value: 1.0 }
    };

    public var vertexShader:String = "
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    ";

    public var fragmentShader:String = "
        uniform float opacity;
        uniform sampler2D tDiffuse;
        varying vec2 vUv;
        #include <packing>
        void main() {
            float depth = 1.0 - unpackRGBAToDepth( texture2D( tDiffuse, vUv ) );
            gl_FragColor = vec4( vec3( depth ), opacity );
        }
    ";
}

typedef UnpackDepthRGBAShaderUniforms = {
    tDiffuse:{ value:null },
    opacity:{ value:Float }
}