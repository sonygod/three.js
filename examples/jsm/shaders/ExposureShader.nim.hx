package three.examples.jsm.shaders;

import js.Lib;
import three.UniformsLib;
import three.UniformsUtils;
import three.WebGLRenderer;
import three.WebGLShaders;

/**
 * Exposure shader
 */
class ExposureShader {

    public static var name: String = 'ExposureShader';

    public static var uniforms: js.Dynamic = {
        'tDiffuse': { value: null },
        'exposure': { value: 1.0 }
    };

    public static var vertexShader: String = Lib.eval(
        'varying vec2 vUv;\n\n' +
        'void main() {\n' +
        '    vUv = uv;\n' +
        '    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n' +
        '}'
    );

    public static var fragmentShader: String = Lib.eval(
        'uniform float exposure;\n\n' +
        'uniform sampler2D tDiffuse;\n\n' +
        'varying vec2 vUv;\n\n' +
        'void main() {\n' +
        '    gl_FragColor = texture2D( tDiffuse, vUv );\n' +
        '    gl_FragColor.rgb *= exposure;\n' +
        '}'
    );

    public static function main(): Void {
        var shader = WebGLShaders.ExposureShader;
        if (shader == null) {
            shader = new ExposureShader();
            WebGLShaders.ExposureShader = shader;
        }

        shader.uniforms = UniformsUtils.clone(shader.uniforms);
        shader.uniforms['tDiffuse'].value = null;
        shader.uniforms['exposure'].value = 1.0;

        var vertexGlsl = WebGLRenderer.getShader(shader.vertexShader, 'vertex');
        var fragmentGlsl = WebGLRenderer.getShader(shader.fragmentShader, 'fragment');

        shader.program = WebGLRenderer.createProgram(vertexGlsl, fragmentGlsl);

        shader.attributes = {
            'position': WebGLRenderer.getAttribLocation(shader.program, 'position'),
            'uv': WebGLRenderer.getAttribLocation(shader.program, 'uv')
        };

        shader.uniforms = UniformsUtils.clone(shader.uniforms);
        shader.uniformsList = UniformsLib.clone(shader.uniforms);
    }
}