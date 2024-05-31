class ShaderUtils {
  public static function getAmbientOcclusion():String {
    var result:String = "";

    #if USE_AOMAP
      result += /*glsl */`
        // reads channel R, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
        float ambientOcclusion = ( texture2D( aoMap, vAoMapUv ).r - 1.0 ) * aoMapIntensity + 1.0;

        reflectedLight.indirectDiffuse *= ambientOcclusion;

        #if defined( USE_CLEARCOAT ) 
          clearcoatSpecularIndirect *= ambientOcclusion;
        #end

        #if defined( USE_SHEEN ) 
          sheenSpecularIndirect *= ambientOcclusion;
        #end

        #if defined( USE_ENVMAP ) && defined( STANDARD )

          float dotNV = saturate( dot( geometryNormal, geometryViewDir ) );

          reflectedLight.indirectSpecular *= computeSpecularOcclusion( dotNV, ambientOcclusion, material.roughness );

        #end
      `;
    #end

    return result;
  }
}