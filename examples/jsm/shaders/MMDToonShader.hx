package three.js.examples.javascript.shaders;

import three.js.UniformsUtils;
import three.js.ShaderLib;

class MMDToonShader {
    public static var name:String = 'MMDToonShader';

    public static var defines:Dynamic = {
        TOON: true,
        MATCAP: true,
        MATCAP_BLENDING_ADD: true,
    };

    public static var uniforms:Dynamic = UniformsUtils.merge([
        ShaderLib.toon.uniforms,
        ShaderLib.phong.uniforms,
        ShaderLib.matcap.uniforms,
    ]);

    public static var vertexShader:String = ShaderLib.phong.vertexShader
        .replace('#include <envmap_pars_vertex>', '')
        .replace('#include <envmap_vertex>', '');

    public static var fragmentShader:String = ShaderLib.phong.fragmentShader
        .replace('#include <common>',
            '
#ifdef USE_MATCAP
    uniform sampler2D matcap;
#endif

#include <common>
        ')
        .replace('#include <envmap_common_pars_fragment>',
            '#include <gradientmap_pars_fragment>'
        )
        .replace('#include <envmap_pars_fragment>', '')
        .replace('#include <lights_phong_pars_fragment>', lightsMMDToonParsFragment)
        .replace('#include <envmap_fragment>',
            '
${mmdToonMatcapFragment}
        ');
}

class LightsMMDToonParsFragment {
    public static var code:String = '
varying vec3 vViewPosition;

struct BlinnPhongMaterial {
    vec3 diffuseColor;
    vec3 specularColor;
    float specularShininess;
    float specularStrength;
};

void RE_Direct_BlinnPhong(const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight) {
    vec3 irradiance = getGradientIrradiance(geometryNormal, directLight.direction) * directLight.color;

    reflectedLight.directDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);

    reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong(directLight.direction, geometryViewDir, geometryNormal, material.specularColor, material.specularShininess) * material.specularStrength;
}

void RE_IndirectDiffuse_BlinnPhong(const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight) {
    reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
}

#define RE_Direct RE_Direct_BlinnPhong
#define RE_IndirectDiffuse RE_IndirectDiffuse_BlinnPhong
';
}

class MMDToonMatcapFragment {
    public static var code:String = '
#ifdef USE_MATCAP

    vec3 viewDir = normalize(vViewPosition);
    vec3 x = normalize(vec3(viewDir.z, 0.0, -viewDir.x));
    vec3 y = cross(viewDir, x);
    vec2 uv = vec2(dot(x, normal), dot(y, normal)) * 0.495 + 0.5; // 0.495 to remove artifacts caused by undersized matcap disks
    vec4 matcapColor = texture2D(matcap, uv);

#ifdef MATCAP_BLENDING_MULTIPLY

    outgoingLight *= matcapColor.rgb;

#elif defined(MATCAP_BLENDING_ADD)

    outgoingLight += matcapColor.rgb;

#endif

#endif
';
}