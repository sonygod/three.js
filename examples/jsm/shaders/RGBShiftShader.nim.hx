package three.examples.jsm.shaders;

import three.ShaderLib;
import three.UniformsLib;
import three.UniformsUtils;
import three.WebGLRenderTarget;
import three.WebGLRenderer;
import three.WebGLShader;

class RGBShiftShader extends ShaderLib {

    public static var name: String = 'RGBShiftShader';

    public static var uniforms: UniformsLib = UniformsUtils.merge([
        UniformsLib.common,
        UniformsLib.diffuse,
        {
            'amount': { value: 0.005 },
            'angle': { value: 0.0 }
        }
    ]);

    public static var vertexShader: String = [
        'varying vec2 vUv;',
        '',
        'void main() {',
        '    vUv = uv;',
        '    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
        '}'
    ].join('\n');

    public static var fragmentShader: String = [
        'uniform sampler2D tDiffuse;',
        'uniform float amount;',
        'uniform float angle;',
        '',
        'varying vec2 vUv;',
        '',
        'void main() {',
        '    vec2 offset = amount * vec2( cos(angle), sin(angle));',
        '    vec4 cr = texture2D(tDiffuse, vUv + offset);',
        '    vec4 cga = texture2D(tDiffuse, vUv);',
        '    vec4 cb = texture2D(tDiffuse, vUv - offset);',
        '    gl_FragColor = vec4(cr.r, cga.g, cb.b, cga.a);',
        '}'
    ].join('\n');

    public static function build(renderer: WebGLRenderer, inputBuffer: WebGLRenderTarget, outputBuffer: WebGLRenderTarget, clearColor: Bool, clearAlpha: Bool): WebGLShader {
        return new WebGLShader(renderer, {
            uniforms: uniforms,
            vertexShader: vertexShader,
            fragmentShader: fragmentShader
        }, inputBuffer, outputBuffer, clearColor, clearAlpha);
    }
}