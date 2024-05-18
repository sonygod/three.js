package three.js.examples.jm.shaders;

import haxe.ds.StringMap;

class SepiaShader {
    public static var NAME:String = 'SepiaShader';

    private var _uniforms:Map<String, Dynamic> = [
        'tDiffuse' => null,
        'amount' => 1.0
    ];

    private var _vertexShader:String = '
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    ';

    private var _fragmentShader:String = '
        uniform float amount;
        uniform sampler2D tDiffuse;
        varying vec2 vUv;

        void main() {
            vec4 color = texture2D( tDiffuse, vUv );
            vec3 c = color.rgb;

            color.r = dot( c, vec3( 1.0 - 0.607 * amount, 0.769 * amount, 0.189 * amount ) );
            color.g = dot( c, vec3( 0.349 * amount, 1.0 - 0.314 * amount, 0.168 * amount ) );
            color.b = dot( c, vec3( 0.272 * amount, 0.534 * amount, 1.0 - 0.869 * amount ) );

            gl_FragColor = vec4( min( vec3( 1.0 ), color.rgb ), color.a );
        }
    ';

    public function new() {}

    public function getUniforms():Map<String, Dynamic> {
        return _uniforms;
    }

    public function getVertexShader():String {
        return _vertexShader;
    }

    public function getFragmentShader():String {
        return _fragmentShader;
    }
}