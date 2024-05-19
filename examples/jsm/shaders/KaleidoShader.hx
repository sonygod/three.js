package three.js.examples.jls.shaders;

import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.geom.Matrix3D;
import openfl.Vector;

class KaleidoShader {
    public var name:String = 'KaleidoShader';

    private var _uniforms:Map<String, ShaderParameter> = [
        'tDiffuse' => { value: null },
        'sides' => { value: 6.0 },
        'angle' => { value: 0.0 }
    ];

    private var _vertexShader:String = '
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }';

    private var _fragmentShader:String = '
        uniform sampler2D tDiffuse;
        uniform float sides;
        uniform float angle;

        varying vec2 vUv;

        void main() {
            vec2 p = vUv - 0.5;
            float r = length(p);
            float a = atan(p.y, p.x) + angle;
            float tau = 2. * 3.1416 ;
            a = mod(a, tau/sides);
            a = abs(a - tau/sides/2.) ;
            p = r * vec2(cos(a), sin(a));
            vec4 color = texture2D(tDiffuse, p + 0.5);
            gl_FragColor = color;
        }';

    public function new() {}

    public function getShader():Shader {
        var shader:Shader = new Shader();
        shader.vertexShader = _vertexShader;
        shader.fragmentShader = _fragmentShader;
        shader.data.tDiffuse.input = ShaderInput.Texture2D;
        shader.data.sides.value = [6.0];
        shader.data.angle.value = [0.0];
        return shader;
    }
}