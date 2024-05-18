package three.js.examples.jsm.shaders;

import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class MirrorShader {
    public static var shader:Shader;

    public static function init() {
        shader = new Shader();

        // Uniforms
        shader.data.tDiffuse.input = ShaderInput.fromTexture2D("tDiffuse", 0);
        shader.data.side.value = [1];

        // Vertex shader
        shader.glslVersion = Shader.GLSL_150;
        shader.vertexShader = "
            varying vec2 vUv;

            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }
        ";

        // Fragment shader
        shader.fragmentShader = "
            uniform sampler2D tDiffuse;
            uniform int side;

            varying vec2 vUv;

            void main() {
                vec2 p = vUv;
                if (side == 0) {
                    if (p.x > 0.5) p.x = 1.0 - p.x;
                } else if (side == 1) {
                    if (p.x < 0.5) p.x = 1.0 - p.x;
                } else if (side == 2) {
                    if (p.y < 0.5) p.y = 1.0 - p.y;
                } else if (side == 3) {
                    if (p.y > 0.5) p.y = 1.0 - p.y;
                }
                vec4 color = texture2D(tDiffuse, p);
                gl_FragColor = color;
            }
        ";
    }
}