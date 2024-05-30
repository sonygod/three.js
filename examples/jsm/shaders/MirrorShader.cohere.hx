package;

import js.WebGL.WebGLProgram;
import js.WebGL.WebGLRenderingContext;
import js.WebGL.WebGLShader;

class MirrorShader {
    public var name: String = 'MirrorShader';
    public var uniforms: { [key: String]: { value: Dynamic } } = {
        'tDiffuse': { value: null },
        'side': { value: 1 }
    };
    public var vertexShader: String = '
        varying vec2 vUv;

        void main() {

            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

        }';
    public var fragmentShader: String = '
        uniform sampler2D tDiffuse;
        uniform int side;

        varying vec2 vUv;

        void main() {

            vec2 p = vUv;
            if (side == 0) {
                if (p.x > 0.5) p.x = 1.0 - p.x;
            } else if (side == 1) {
                if (p.x < 0.5) p.x = 1.0 - p.x;
            } else if (side == 2) {
                if (p.y < 0.5) p.y = 1.0 - p.y;
            } else if (side == 3) {
                if (p.y > 0.5) p.y = 1.0 - p.y;
            }
            vec4 color = texture2D(tDiffuse, p);
            gl_FragColor = color;

        }';

    public function new(): Void;
    public function new() {
    }

    public function init(gl: WebGLRenderingContext): Void;
    public function init(gl: WebGLRenderingContext) {
        var vertexShader: WebGLShader = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertexShader, vertexShader);
        gl.compileShader(vertexShader);

        var fragmentShader: WebGLShader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragmentShader, fragmentShader);
        gl.compileShader(fragmentShader);

        var program: WebGLProgram = gl.createProgram();
        gl.attachShader(program, vertexShader);
        gl.attachShader(program, fragmentShader);
        gl.linkProgram(program);

        this.uniforms['tDiffuse'].value = { t: gl.getUniformLocation(program, 'tDiffuse') };
        this.uniforms['side'].value = { t: gl.getUniformLocation(program, 'side') };
    }
}