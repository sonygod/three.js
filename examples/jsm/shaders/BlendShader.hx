package three.js.examples.jvm.shaders;

import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class BlendShader {
    public var name:String;

    public var uniforms:Map<String, ShaderParameter>;

    public function new() {
        name = 'BlendShader';

        uniforms = new Map<String, ShaderParameter>();
        uniforms.set('tDiffuse1', new ShaderParameter('tDiffuse1', ShaderInput.Texture2D));
        uniforms.set('tDiffuse2', new ShaderParameter('tDiffuse2', ShaderInput.Texture2D));
        uniforms.set('mixRatio', new ShaderParameter('mixRatio', ShaderInput.Float));
        uniforms.set('opacity', new ShaderParameter('opacity', ShaderInput.Float));

        var vertexShader:String = "
            varying vec2 vUv;

            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }
        ";

        var fragmentShader:String = "
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
        ";

        var shader:Shader = new Shader();
        shader.glVertexShader = vertexShader;
        shader.glFragmentShader = fragmentShader;

        // todo: implement shader compilation and error handling
    }
}