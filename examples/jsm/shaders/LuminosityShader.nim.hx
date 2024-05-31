package three.examples.jsm.shaders;

import js.html.WebGLRenderingContext;
import three.ShaderLib;
import three.UniformsLib;
import three.UniformsUtils;

class LuminosityShader implements ShaderLib {

    public static var name:String = 'LuminosityShader';

    public static var uniforms:UniformsLib = {
        'tDiffuse': { value: null }
    };

    public static var vertexShader:String = [
        'varying vec2 vUv;',
        '',
        'void main() {',
        '    vUv = uv;',
        '    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
        '}'
    ].join('\n');

    public static var fragmentShader:String = [
        '#include <common>',
        '',
        'uniform sampler2D tDiffuse;',
        'varying vec2 vUv;',
        '',
        'void main() {',
        '    vec4 texel = texture2D( tDiffuse, vUv );',
        '    float l = luminance( texel.rgb );',
        '    gl_FragColor = vec4( l, l, l, texel.w );',
        '}'
    ].join('\n');

    public static function build():UniformsLib {
        return UniformsUtils.merge([ShaderLib.common, ShaderLib.lights, uniforms]);
    }

    public static function init(renderer:WebGLRenderingContext):void {
        renderer.shaderLib[name] = new LuminosityShader();
    }

}