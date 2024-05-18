package three.js.examples.jvm.shaders;

import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.display.ShaderPrecision;

class ACESFilmicToneMappingShader {
    public static var NAME:String = 'ACESFilmicToneMappingShader';

    private var _shader:Shader;

    public function new() {
        _shader = new Shader();
        _shader.glslVersion = ShaderPrecision.FP30;

        _shader.vertexShader = '
            varying vec2 vUv;

            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }
        ';

        _shader.fragmentShader = '
            #define saturate(a) clamp( a, 0.0, 1.0 )

            uniform sampler2D tDiffuse;
            uniform float exposure;

            varying vec2 vUv;

            vec3 RRTAndODTFit( vec3 v ) {
                vec3 a = v * ( v + 0.0245786 ) - 0.000090537;
                vec3 b = v * ( 0.983729 * v + 0.4329510 ) + 0.238081;
                return a / b;
            }

            vec3 ACESFilmicToneMapping( vec3 color ) {
                const mat3 ACESInputMat = mat3(
                    vec3( 0.59719, 0.07600, 0.02840 ),
                    vec3( 0.35458, 0.90834, 0.13383 ),
                    vec3( 0.04823, 0.01566, 0.83777 )
                );

                const mat3 ACESOutputMat = mat3(
                    vec3(  1.60475, -0.10208, -0.00327 ),
                    vec3( -0.53108,  1.10813, -0.07276 ),
                    vec3( -0.07367, -0.00605,  1.07602 )
                );

                color = ACESInputMat * color;
                color = RRTAndODTFit( color );
                color = ACESOutputMat * color;
                return saturate( color );
            }

            void main() {
                vec4 tex = texture2D( tDiffuse, vUv );
                tex.rgb *= exposure / 0.6;
                gl_FragColor = vec4( ACESFilmicToneMapping( tex.rgb ), tex.a );
            }
        ';

        _shader.data.tDiffuse.input = ShaderInput.Texture2D;
        _shader.data.exposure.value = [1.0];
    }

    public function getShader():Shader {
        return _shader;
    }
}