package three.js.examples.jm.shaders;

import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

/**
 * Brightness and contrast adjustment
 * https://github.com/evanw/glfx.js
 * brightness: -1 to 1 (-1 is solid black, 0 is no change, and 1 is solid white)
 * contrast: -1 to 1 (-1 is solid gray, 0 is no change, and 1 is maximum contrast)
 */

class BrightnessContrastShader {

    public static var NAME:String = "BrightnessContrastShader";

    private var shader:Shader;

    public function new() {
        shader = new Shader();

        shader.data.tDiffuse.input = ShaderInputTexture2D;
        shader.data.brightness.value = [0.0];
        shader.data.contrast.value = [0.0];

        shader.glslVersion = Shader.GLCONTEXT_WEBGL;

        shader.vertexShader = "
            varying vec2 vUv;

            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }
        ";

        shader.fragmentShader = "
            uniform sampler2D tDiffuse;
            uniform float brightness;
            uniform float contrast;

            varying vec2 vUv;

            void main() {
                gl_FragColor = texture2D(tDiffuse, vUv);

                gl_FragColor.rgb += brightness;

                if (contrast > 0.0) {
                    gl_FragColor.rgb = (gl_FragColor.rgb - 0.5) / (1.0 - contrast) + 0.5;
                } else {
                    gl_FragColor.rgb = (gl_FragColor.rgb - 0.5) * (1.0 + contrast) + 0.5;
                }
            }
        ";
    }

    public function getShader():Shader {
        return shader;
    }
}