package three.js.examples.javascript;

import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class HorizontalBlurShader {
    public static var shader:Shader;

    public static function init():Void {
        shader = new Shader();

        shader.glslVersion = ShaderVersion.GL2;

        shader.vertexShader = "
            varying vec2 vUv;

            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }
        ";

        shader.fragmentShader = "
            uniform sampler2D tDiffuse;
            uniform float h;

            varying vec2 vUv;

            void main() {
                vec4 sum = vec4( 0.0 );

                sum += texture2D( tDiffuse, vec2( vUv.x - 4.0 * h, vUv.y ) ) * 0.051;
                sum += texture2D( tDiffuse, vec2( vUv.x - 3.0 * h, vUv.y ) ) * 0.0918;
                sum += texture2D( tDiffuse, vec2( vUv.x - 2.0 * h, vUv.y ) ) * 0.12245;
                sum += texture2D( tDiffuse, vec2( vUv.x - 1.0 * h, vUv.y ) ) * 0.1531;
                sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y ) ) * 0.1633;
                sum += texture2D( tDiffuse, vec2( vUv.x + 1.0 * h, vUv.y ) ) * 0.1531;
                sum += texture2D( tDiffuse, vec2( vUv.x + 2.0 * h, vUv.y ) ) * 0.12245;
                sum += texture2D( tDiffuse, vec2( vUv.x + 3.0 * h, vUv.y ) ) * 0.0918;
                sum += texture2D( tDiffuse, vec2( vUv.x + 4.0 * h, vUv.y ) ) * 0.051;

                gl_FragColor = sum;
            }
        ";

        shader.data.tDiffuse.input = ShaderInput.Texture2D;
        shader.data.h.value = [1.0 / 512.0];
    }
}