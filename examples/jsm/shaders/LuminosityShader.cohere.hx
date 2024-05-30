package;

import js.WebGL.WebGLProgram;
import js.WebGL.WebGLRenderingContext;
import js.WebGL.WebGLShader;
import js.WebGL.WebGLUniforms;

class LuminosityShader {
    public var name: String = "LuminosityShader";
    public var uniforms: WebGLUniforms;
    public var vertexShader: String;
    public var fragmentShader: String;

    public function new() {
        uniforms = {
            "tDiffuse": { value: null }
        };

        vertexShader = """
            varying vec2 vUv;
            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }
        """;

        fragmentShader = """
            #include <common>
            uniform sampler2D tDiffuse;
            varying vec2 vUv;
            void main() {
                vec4 texel = texture2D( tDiffuse, vUv );
                float l = luminance( texel.rgb );
                gl_FragColor = vec4( l, l, l, texel.w );
            }
        """;
    }
}