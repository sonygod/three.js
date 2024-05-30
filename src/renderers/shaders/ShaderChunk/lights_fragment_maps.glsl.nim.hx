package three.js.src.renderers.shaders.ShaderChunk;

class lights_fragment_maps {
    static function main() {
        #if defined( RE_IndirectDiffuse )
            #ifdef USE_LIGHTMAP
                var lightMapTexel = texture2D(lightMap, vLightMapUv);
                var lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;
                irradiance += lightMapIrradiance;
            #end
            #if defined( USE_ENVMAP ) && defined( STANDARD ) && defined( ENVMAP_TYPE_CUBE_UV )
                iblIrradiance += getIBLIrradiance(geometryNormal);
            #end
        #end
        #if defined( USE_ENVMAP ) && defined( RE_IndirectSpecular )
            #ifdef USE_ANISOTROPY
                radiance += getIBLAnisotropyRadiance(geometryViewDir, geometryNormal, material.roughness, material.anisotropyB, material.anisotropy);
            #else
                radiance += getIBLRadiance(geometryViewDir, geometryNormal, material.roughness);
            #end
            #ifdef USE_CLEARCOAT
                clearcoatRadiance += getIBLRadiance(geometryViewDir, geometryClearcoatNormal, material.clearcoatRoughness);
            #end
        #end
    }
}