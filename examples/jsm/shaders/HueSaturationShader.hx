package three.js.examples.jsm.shaders;

import openfl.display3D.Context3D;
import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DBufferUsage;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.Program3D;
import openfl.display3D.Shader;
import openfl.display3D.ShaderInput;
import openfl.display3D.Texture;
import openfl.utils.ByteArray;
import openfl.utils.Endian;

class HueSaturationShader {
    public static var NAME:String = 'HueSaturationShader';

    private var _program:Program3D;
    private var _vertexShader:String;
    private var _fragmentShader:String;

    public function new() {
        _vertexShader = "
            varying vec2 vUv;

            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }
        ";

        _fragmentShader = "
            uniform sampler2D tDiffuse;
            uniform float hue;
            uniform float saturation;

            varying vec2 vUv;

            void main() {
                gl_FragColor = texture2D(tDiffuse, vUv);

                // hue
                float angle = hue * 3.14159265;
                float s = sin(angle), c = cos(angle);
                vec3 weights = (vec3(2.0 * c, -sqrt(3.0) * s - c, sqrt(3.0) * s - c) + 1.0) / 3.0;
                float len = length(gl_FragColor.rgb);
                gl_FragColor.rgb = vec3(
                    dot(gl_FragColor.rgb, weights.xyz),
                    dot(gl_FragColor.rgb, weights.zxy),
                    dot(gl_FragColor.rgb, weights.yzx)
                );

                // saturation
                float average = (gl_FragColor.r + gl_FragColor.g + gl_FragColor.b) / 3.0;
                if (saturation > 0.0) {
                    gl_FragColor.rgb += (average - gl_FragColor.rgb) * (1.0 - 1.0 / (1.001 - saturation));
                } else {
                    gl_FragColor.rgb += (average - gl_FragColor.rgb) * (-saturation);
                }
            }
        ";

        _program = Context3D.getcontext().createProgram();
        _program.upload(
            _vertexShader,
            _fragmentShader
        );
    }

    public function getUniform(name:String):ShaderInput {
        return _program.getUniformLocation(name);
    }

    public function setUniform(name:String, value:Dynamic):Void {
        _program.setUniformLocation(getUniform(name), value);
    }

    public function dispose():Void {
        _program.dispose();
    }
}