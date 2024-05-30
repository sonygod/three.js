package;

import js.WebGL.WebGLProgram;
import js.WebGL.WebGLRenderingContext;
import js.WebGL.WebGLShader;
import js.WebGL.WebGLUniformLocation;

class HueSaturationShader {
    public var name: String = 'HueSaturationShader';
    public var uniforms: { [key: String]: { value: Dynamic } } = {
        'tDiffuse': { value: null },
        'hue': { value: 0.0 },
        'saturation': { value: 0.0 }
    };

    public var vertexShader: String = """
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    """;

    public var fragmentShader: String = """
        uniform sampler2D tDiffuse;
        uniform float hue;
        uniform float saturation;
        varying vec2 vUv;

        void main() {
            gl_FragColor = texture2D( tDiffuse, vUv );

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
    """;

    public function init(gl: WebGLRenderingContext): Void {
        var vertexShader: WebGLShader = gl.createShader(gl.VERTEX_SHADER);
        var fragmentShader: WebGLShader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(vertexShader, vertexShader);
        gl.shaderSource(fragmentShader, fragmentShader);
        gl.compileShader(vertexShader);
        gl.compileShader(fragmentShader);

        var program: WebGLProgram = gl.createProgram();
        gl.attachShader(program, vertexShader);
        gl.attachShader(program, fragmentShader);
        gl.linkProgram(program);

        gl.useProgram(program);

        var tDiffuse: WebGLUniformLocation = gl.getUniformLocation(program, 'tDiffuse');
        var hue: WebGLUniformLocation = gl.getUniformLocation(program, 'hue');
        var saturation: WebGLUniformLocation = gl.getUniformLocation(program, 'saturation');

        uniforms.get('tDiffuse').value = tDiffuse;
        uniforms.get('hue').value = hue;
        uniforms.get('saturation').value = saturation;
    }
}