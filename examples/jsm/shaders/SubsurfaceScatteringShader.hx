Here is the converted Haxe code:
```
package three.js.examples.jsm.shaders;

import three.Color;
import three.ShaderChunk;
import three.ShaderLib;
import three.UniformsUtils;

class SubsurfaceScatteringShader {
    public static var name:String = 'SubsurfaceScatteringShader';

    public static var uniforms:Any = UniformsUtils.merge([
        ShaderLib.phong.uniforms,
        {
            'thicknessMap': { value: null },
            'thicknessColor': { value: new Color(0xffffff) },
            'thicknessDistortion': { value: 0.1 },
            'thicknessAmbient': { value: 0.0 },
            'thicknessAttenuation': { value: 0.1 },
            'thicknessPower': { value: 2.0 },
            'thicknessScale': { value: 10.0 }
        }
    ]);

    public static var vertexShader:String = [
        '#define USE_UV',
        ShaderChunk.meshphong_vert
    ].join('\n');

    public static var fragmentShader:String = [
        '#define USE_UV',
        '#define SUBSURFACE',

        meshphong_frag_head,

        'uniform sampler2D thicknessMap;',
        'uniform float thicknessPower;',
        'uniform float thicknessScale;',
        'uniform float thicknessDistortion;',
        'uniform float thicknessAmbient;',
        'uniform float thicknessAttenuation;',
        'uniform vec3 thicknessColor;',

        'void RE_Direct_Scattering(const in IncidentLight directLight, const in vec2 uv, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, inout ReflectedLight reflectedLight) {',
        '    vec3 thickness = thicknessColor * texture2D(thicknessMap, uv).r;',
        '    vec3 scatteringHalf = normalize(directLight.direction + (geometryNormal * thicknessDistortion));',
        '    float scatteringDot = pow(saturate(dot(geometryViewDir, -scatteringHalf)), thicknessPower) * thicknessScale;',
        '    vec3 scatteringIllu = (scatteringDot + thicknessAmbient) * thickness;',
        '    reflectedLight.directDiffuse += scatteringIllu * thicknessAttenuation * directLight.color;',
        '}',

        meshphong_frag_body.replace(
            '#include <lights_fragment_begin>',

            replaceAll(
                ShaderChunk.lights_fragment_begin,
                'RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );',
                [
                    'RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );',

                    '#if defined( SUBSURFACE ) && defined( USE_UV )',
                    ' RE_Direct_Scattering(directLight, vUv, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, reflectedLight);',
                    '#endif',
                ].join('\n')
            )
        )
    ].join('\n');
}

function replaceAll(string:String, find:String, replace:String):String {
    return string.split(find).join(replace);
}
```
Note that I had to make some assumptions about the Haxe syntax, as it's not identical to JavaScript. I also removed the `export` statement, as it's not necessary in Haxe.