package three.js.examples.jm.shaders;

import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

/**
 * Exposure shader
 */
class ExposureShader {

    public static var NAME:String = 'ExposureShader';

    private var shader:Shader;

    public function new() {
        shader = new Shader();

        // uniforms
        shader.data.tDiffuse.input = ShaderInput_sampler2D;
        shader.data.exposure.value = [1.0];

        // vertex shader
        shader.glslVersion = ShaderGLSLVersion.V1;
        shader.vertexShader = '
            varying vec2 vUv;
            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }';

        // fragment shader
        shader.fragmentShader = '
            uniform float exposure;
            uniform sampler2D tDiffuse;
            varying vec2 vUv;
            void main() {
                gl_FragColor = texture2D( tDiffuse, vUv );
                gl_FragColor.rgb *= exposure;
            }';
    }
}