package three.js.examples.javascript.shaders;

import js.html.webgl.Shader;
import js.html.webgl.UniformLocation;
import js.html.webgl.RenderingContext;

class BrightnessContrastShader {
    public static var name:String = 'BrightnessContrastShader';

    private var uniforms:Map<String, Dynamic> = [
        'tDiffuse' => { value: null },
        'brightness' => { value: 0.0 },
        'contrast' => { value: 0.0 }
    ];

    private var vertexShader:String = "
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    ";

    private var fragmentShader:String = "
        uniform sampler2D tDiffuse;
        uniform float brightness;
        uniform float contrast;

        varying vec2 vUv;

        void main() {
            gl_FragColor = texture2D( tDiffuse, vUv );
            gl_FragColor.rgb += brightness;
            if (contrast > 0.0) {
                gl_FragColor.rgb = (gl_FragColor.rgb - 0.5) / (1.0 - contrast) + 0.5;
            } else {
                gl_FragColor.rgb = (gl_FragColor.rgb - 0.5) * (1.0 + contrast) + 0.5;
            }
        }
    ";

    public function new() {}

    public function setupShader(gl:RenderingContext, program:Shader):Void {
        // todo: implement shader setup
    }
}