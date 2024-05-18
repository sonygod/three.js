package three.shader;

import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Program3D;

class DOFMipMapShader {
    public var name:String = 'DOFMipMapShader';

    private var uniforms:Map<String, Dynamic> = [
        'tColor' => { value: null },
        'tDepth' => { value: null },
        'focus' => { value: 1.0 },
        'maxblur' => { value: 1.0 }
    ];

    private var vertexShader:String = "
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    ";

    private var fragmentShader:String = "
        uniform float focus;
        uniform float maxblur;

        uniform sampler2D tColor;
        uniform sampler2D tDepth;

        varying vec2 vUv;

        void main() {
            vec4 depth = texture2D( tDepth, vUv );

            float factor = depth.x - focus;

            vec4 col = texture2D( tColor, vUv, 2.0 * maxblur * abs( focus - depth.x ) );

            gl_FragColor = col;
            gl_FragColor.a = 1.0;
        }
    ";

    public function new() {}

    public function init(context:Context3D):Program3D {
        var program:Program3D = context.createProgram();
        program.upload(vertexShader, fragmentShader);
        return program;
    }
}