package three.js.examples.jsm.shaders;

import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class VignetteShader {
    public static var NAME:String = 'VignetteShader';

    private var _shader:Shader;

    public function new() {
        _shader = new Shader();

        _shaderGLSL(
            vertex:
                "
                varying vec2 vUv;

                void main() {
                    vUv = uv;
                    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
                }
            ",
            fragment:
                "
                uniform float offset;
                uniform float darkness;

                uniform sampler2D tDiffuse;

                varying vec2 vUv;

                void main() {
                    // Eskil's vignette

                    vec4 texel = texture2D( tDiffuse, vUv );
                    vec2 uv = ( vUv - vec2( 0.5 ) ) * vec2( offset );
                    gl_FragColor = vec4( mix( texel.rgb, vec3( 1.0 - darkness ), dot( uv, uv ) ), texel.a );
                }
            "
        );

        _shader.data.offset.value = [1.0];
        _shader.data.darkness.value = [1.0];
        _shader.data.tDiffuse.input = new ShaderInput<ShaderParameter<Dynamic>>(ShaderParameter.FloatType);
    }
}