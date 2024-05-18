package three.renderers.shaders.ShaderChunk.lights_toon_pars_fragment;

import openfl.gl.GLShader;

class LightsToonParsFragment {
    static var shaderSource = "
        varying vec3 vViewPosition;

        struct ToonMaterial {
            vec3 diffuseColor;
        };

        void RE_Direct_Toon(in IncidentLight directLight, in vec3 geometryPosition, in vec3 geometryNormal, in vec3 geometryViewDir, in vec3 geometryClearcoatNormal, in ToonMaterial material, inout ReflectedLight reflectedLight) {
            vec3 irradiance = getGradientIrradiance(geometryNormal, directLight.direction) * directLight.color;
            reflectedLight.directDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
        }

        void RE_IndirectDiffuse_Toon(in vec3 irradiance, in vec3 geometryPosition, in vec3 geometryNormal, in vec3 geometryViewDir, in vec3 geometryClearcoatNormal, in ToonMaterial material, inout ReflectedLight reflectedLight) {
            reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);
        }

        #define RE_Direct RE_Direct_Toon
        #define RE_IndirectDiffuse RE_IndirectDiffuse_Toon
    ";
}