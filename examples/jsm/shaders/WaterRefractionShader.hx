package three.js.examples.javascript.shaders;

import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class WaterRefractionShader {
    public static var NAME:String = 'WaterRefractionShader';

    private var shader:Shader;

    public function new() {
        shader = new Shader();

        // uniforms
        var uniforms:Array<ShaderParameter> = [
            new ShaderParameter Float('time', 0),
            new ShaderParameter Texture('tDiffuse', null),
            new ShaderParameter Texture('tDudv', null),
            new ShaderParameter Matrix('textureMatrix', null),
            new ShaderParameter Vec3('color', null)
        ];
        shader.data.uniforms = uniforms;

        // vertex shader
        shader.vertexShader = '
            uniform mat4 textureMatrix;

            varying vec2 vUv;
            varying vec4 vUvRefraction;

            void main() {
                vUv = uv;
                vUvRefraction = textureMatrix * vec4(position, 1.0);
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }
        ';

        // fragment shader
        shader.fragmentShader = '
            uniform vec3 color;
            uniform float time;
            uniform sampler2D tDiffuse;
            uniform sampler2D tDudv;

            varying vec2 vUv;
            varying vec4 vUvRefraction;

            float blendOverlay(float base, float blend) {
                return (base < 0.5) ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend));
            }

            vec3 blendOverlay(vec3 base, vec3 blend) {
                return vec3(blendOverlay(base.r, blend.r), blendOverlay(base.g, blend.g), blendOverlay(base.b, blend.b));
            }

            void main() {
                float waveStrength = 0.5;
                float waveSpeed = 0.03;

                vec2 distortedUv = texture2D(tDudv, vec2(vUv.x + time * waveSpeed, vUv.y)).rg * waveStrength;
                distortedUv = vUv.xy + vec2(distortedUv.x, distortedUv.y + time * waveSpeed);
                vec2 distortion = (texture2D(tDudv, distortedUv).rg * 2.0 - 1.0) * waveStrength;

                vec4 uv = vec4(vUvRefraction);
                uv.xy += distortion;

                vec4 base = texture2DProj(tDiffuse, uv);

                gl_FragColor = vec4(blendOverlay(base.rgb, color), 1.0);

                #include <tonemapping_fragment>
                #include <colorspace_fragment>
            }
        ';
    }
}