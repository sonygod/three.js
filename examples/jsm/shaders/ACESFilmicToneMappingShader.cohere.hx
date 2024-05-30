package openfl.display3D.textures;

import openfl.display3D.Context3D;
import openfl.display3D.Program3D;
import openfl.display3D.Uniform;
import openfl.display3D.VertexBuffer3D;

class ACESFilmicToneMappingShader {
    public var name:String = "ACESFilmicToneMappingShader";
    public var context:Context3D;
    public var program:Program3D;
    public var uniforms:Array<Dynamic>;

    public function new(context:Context3D) {
        this.context = context;
        this.init();
    }

    public function init():Void {
        var vertexShader:String = #"""
            varying vec2 vUv;

            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }
        """#;

        var fragmentShader:String = #"""
            #define saturate(a) clamp(a, 0.0, 1.0)

            uniform sampler2D tDiffuse;
            uniform float exposure;
            varying vec2 vUv;

            vec3 RRTAndODTFit(vec3 v) {
                vec3 a = v * (v + 0.0245786) - 0.000090537;
                vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
                return a / b;
            }

            vec3 ACESFilmicToneMapping(vec3 color) {
                const mat3 ACESInputMat = mat3(
                    0.59719, 0.07600, 0.02840,
                    0.35458, 0.90834, 0.13383,
                    0.04823, 0.01566, 0.83777
                );

                const mat3 ACESOutputMat = mat3(
                    1.60475, -0.10208, -0.00327,
                    -0.53108, 1.10813, -0.07276,
                    -0.07367, -0.00605, 1.07602
                );

                color = ACESInputMat * color;
                color = RRTAndODTFit(color);
                color = ACESOutputMat * color;
                return saturate(color);
            }

            void main() {
                vec4 tex = texture2D(tDiffuse, vUv);
                tex.rgb *= exposure / 0.6;
                gl_FragColor = vec4(ACESFilmicToneMapping(tex.rgb), tex.a);
            }
        """#;

        program = context.createProgram();
        program.upload(vertexShader, fragmentShader);

        uniforms = [
            {"type": "sampler2D", "name": "tDiffuse"},
            {"type": "1f", "name": "exposure"}
        ];
    }

    public function uploadTexture(texture:TextureBase):Void {
        var diffuse:Uniform = program.getUniform("tDiffuse");
        diffuse.value = texture;
    }

    public function uploadExposure(exposure:Float):Void {
        var exp:Uniform = program.getUniform("exposure");
        exp.value = exposure;
    }

    public function dispose():Void {
        context.deleteProgram(program);
    }
}