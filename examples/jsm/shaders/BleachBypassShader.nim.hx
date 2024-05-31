package three.examples.jsm.shaders;

import js.html.WebGLRenderingContext;
import three.js.UniformsUtils;
import three.js.ShaderLib;
import three.js.ShaderMaterial;
import three.js.UniformsLib;
import three.js.Uniforms;
import three.js.ShaderChunk;

class BleachBypassShader {

    public static var name:String = 'BleachBypassShader';

    public static var uniforms:Uniforms = UniformsUtils.merge([
        UniformsLib.common,
        UniformsLib.map,
        {
            'opacity': { value: 1.0 }
        }
    ]);

    public static var vertexShader:String = [
        'varying vec2 vUv;',
        '',
        'void main() {',
        '',
        '	vUv = uv;',
        '	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
        '}'
    ].join('\n');

    public static var fragmentShader:String = [
        'uniform float opacity;',
        '',
        'uniform sampler2D tDiffuse;',
        '',
        'varying vec2 vUv;',
        '',
        'void main() {',
        '',
        '	vec4 base = texture2D( tDiffuse, vUv );',
        '',
        '	vec3 lumCoeff = vec3( 0.25, 0.65, 0.1 );',
        '	float lum = dot( lumCoeff, base.rgb );',
        '	vec3 blend = vec3( lum );',
        '',
        '	float L = min( 1.0, max( 0.0, 10.0 * ( lum - 0.45 ) ) );',
        '',
        '	vec3 result1 = 2.0 * base.rgb * blend;',
        '	vec3 result2 = 1.0 - 2.0 * ( 1.0 - blend ) * ( 1.0 - base.rgb );',
        '',
        '	vec3 newColor = mix( result1, result2, L );',
        '',
        '	float A2 = opacity * base.a;',
        '	vec3 mixRGB = A2 * newColor.rgb;',
        '	mixRGB += ( ( 1.0 - A2 ) * base.rgb );',
        '',
        '	gl_FragColor = vec4( mixRGB, base.a );',
        '}'
    ].join('\n');

    public static function build(renderer:WebGLRenderingContext):ShaderMaterial {
        return new ShaderMaterial({
            uniforms: uniforms,
            vertexShader: vertexShader,
            fragmentShader: fragmentShader
        });
    }
}