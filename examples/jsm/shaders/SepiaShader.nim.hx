package three.examples.jsm.shaders;

import js.Lib;
import three.ShaderLib;
import three.UniformsLib;
import three.UniformsUtils;
import three.WebGLRenderer;

@:build(three.ShaderLib.build('SepiaShader', fragmentShader, vertexShader))
class SepiaShader extends ShaderLib {

    public static var name:String = 'SepiaShader';

    public static var uniforms:Dynamic = {
        'tDiffuse': { value: null },
        'amount': { value: 1.0 }
    };

    public static var vertexShader:String = Lib.eval(
        'varying vec2 vUv;\n\n' +
        'void main() {\n' +
        '    vUv = uv;\n' +
        '    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n' +
        '}'
    );

    public static var fragmentShader:String = Lib.eval(
        'uniform float amount;\n\n' +
        'uniform sampler2D tDiffuse;\n\n' +
        'varying vec2 vUv;\n\n' +
        'void main() {\n' +
        '    vec4 color = texture2D( tDiffuse, vUv );\n' +
        '    vec3 c = color.rgb;\n\n' +
        '    color.r = dot( c, vec3( 1.0 - 0.607 * amount, 0.769 * amount, 0.189 * amount ) );\n' +
        '    color.g = dot( c, vec3( 0.349 * amount, 1.0 - 0.314 * amount, 0.168 * amount ) );\n' +
        '    color.b = dot( c, vec3( 0.272 * amount, 0.534 * amount, 1.0 - 0.869 * amount ) );\n\n' +
        '    gl_FragColor = vec4( min( vec3( 1.0 ), color.rgb ), color.a );\n' +
        '}'
    );

    public static function build(renderer:WebGLRenderer):String {
        return UniformsUtils.merge([
            UniformsLib.common,
            UniformsLib.fog,
            UniformsLib.lights,
            uniforms
        ]);
    }
}