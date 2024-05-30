package;

import js.WebGL.WebGLProgram;
import js.WebGL.WebGLRenderingContext;
import js.WebGL.WebGLShader;
import js.WebGL.WebGLUniforms;

class BlendShader {
    public var name: String = 'BlendShader';
    public var uniforms: WebGLUniforms;
    public var vertexShader: String = '''
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    ''';
    public var fragmentShader: String = '''
        uniform float opacity;
        uniform float mixRatio;
        uniform sampler2D tDiffuse1;
        uniform sampler2D tDiffuse2;
        varying vec2 vUv;
        void main() {
            vec4 texel1 = texture2D(tDiffuse1, vUv);
            vec4 texel2 = texture2D(tDiffuse2, vUv);
            gl_FragColor = opacity * mix(texel1, texel2, mixRatio);
        }
    ''';

    public function new() {
        uniforms = {
            'tDiffuse1': { value: null },
            'tDiffuse2': { value: null },
            'mixRatio': { value: 0.5 },
            'opacity': { value: 1.0 }
        };
    }
}