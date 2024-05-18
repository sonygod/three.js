package three.js.examples.jsm.shaders;

import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

/**
 * Luminosity
 * http://en.wikipedia.org/wiki/Luminosity
 */
class LuminosityShader {
    public static var NAME:String = 'LuminosityShader';

    private var shader:Shader;

    public function new() {
        shader = new Shader();

        var vertexShader:String = "
            varying vec2 vUv;

            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }";

        var fragmentShader:String = "
            #include <common>
            uniform sampler2D tDiffuse;
            varying vec2 vUv;

            void main() {
                vec4 texel = texture2D(tDiffuse, vUv);
                float l = luminance(texel.rgb);
                gl_FragColor = vec4(l, l, l, texel.w);
            }";

        shader.glslVersion = ShaderGLSLVersion.V300;
        shader.vertexShader = vertexShader;
        shader.fragmentShader = fragmentShader;

        var tDiffuse:ShaderInput<ShaderParameter<Texture>> = shader.findInput("tDiffuse");
        tDiffuse.value = null;
    }
}