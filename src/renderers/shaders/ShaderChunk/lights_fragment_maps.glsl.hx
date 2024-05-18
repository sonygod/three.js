package three.shader;

class LightsFragmentMaps {
    public function new() {}

    public static function fragment() {
        #if defined( RE_IndirectDiffuse )

        #ifdef USE_LIGHTMAP

        var lightMapTexel:Vec4 = texture2D(lightMap, vLightMapUv);
        var lightMapIrradiance:Vec3 = lightMapTexel.rgb * lightMapIntensity;

        irradiance += lightMapIrradiance;

        #endif

        #if defined( USE_ENVMAP ) && defined( STANDARD ) && defined( ENVMAP_TYPE_CUBE_UV )

        iblIrradiance += getIBLIrradiance(geometryNormal);

        #endif

        #end

        #if defined( USE_ENVMAP ) && defined( RE_IndirectSpecular )

        #ifdef USE_ANISOTROPY

        radiance += getIBLAnisotropyRadiance(geometryViewDir, geometryNormal, material.roughness, material.anisotropyB, material.anisotropy);

        #else

        radiance += getIBLRadiance(geometryViewDir, geometryNormal, material.roughness);

        #endif

        #ifdef USE_CLEARCOAT

        clearcoatRadiance += getIBLRadiance(geometryViewDir, geometryClearcoatNormal, material.clearcoatRoughness);

        #endif

        #end
    }
}