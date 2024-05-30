package;

import openfl.display.Shader;
import openfl.display.ShaderParameter;

class HorizontalBlurShader extends Shader {
    public function new() {
        super(null, null);

        // GLSL code for the vertex shader
        vertexSrc = "#version 100
            varying vec2 vUv;
            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }";

        // GLSL code for the fragment shader
        fragmentSrc = "#version 100
            uniform sampler2D tDiffuse;
            uniform float h;
            varying vec2 vUv;
            void main() {
                vec4 sum = vec4(0.0);
                sum += texture2D(tDiffuse, vec2(vUv.x - 4.0 * h, vUv.y)) * 0.051;
                sum += texture2D(tDiffuse, vec2(vUv.x - 3.0 * h, vUv.y)) * 0.0918;
                sum += texture2D(tDiffuse, vec2(vUv.x - 2.0 * h, vUv.y)) * 0.12245;
                sum += texture2D(tDiffuse, vec2(vUv.x - 1.0 * h, vUv.y)) * 0.1531;
                sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y)) * 0.1633;
                sum += texture2D(tDiffuse, vec2(vUv.x + 1.0 * h, vUv.y)) * 0.1531;
                sum += texture2D(tDiffuse, vec2(vUv.x + 2.0 * h, vUv.y)) * 0.12245;
                sum += texture2D(tDiffuse, vec2(vUv.x + 3.0 * h, vUv.y)) * 0.0918;
                sum += texture2D(tDiffuse, vec2(vUv.x + 4.0 * h, vUv.y)) * 0.051;
                gl_FragColor = sum;
            }";

        // Compile and link the shader
        compile();

        // Set default shader parameters
        parameters.set('tDiffuse', new ShaderParameter(null));
        parameters.set('h', new ShaderParameter(1.0 / 512.0));
    }
}