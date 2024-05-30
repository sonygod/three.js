package;

import js.Browser.WebGL.WebGLProgram;
import js.Browser.WebGL.WebGLRenderingContext;

class TechnicolorShader {
    public var name: String = "TechnicolorShader";
    public var uniforms: { [key: String]: { value: Dynamic } } = {
        "tDiffuse": { value: null }
    };
    public var vertexShader: String = """
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    """;
    public var fragmentShader: String = """
        uniform sampler2D tDiffuse;
        varying vec2 vUv;
        void main() {
            vec4 tex = texture2D(tDiffuse, vec2(vUv.x, vUv.y));
            vec4 newTex = vec4(tex.r, (tex.g + tex.b) * 0.5, (tex.g + tex.b) * 0.5, 1.0);
            gl_FragColor = newTex;
        }
    """;

    public function new(): TechnicolorShader;
}