package renderers.shaders.ShaderChunk;

class AOMapFragment {
    #if USE_AOMAP

    // reads channel R, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
    var ambientOcclusion:Float = (texture2D(aoMap, vAoMapUv).r - 1.0) * aoMapIntensity + 1.0;

    reflectedLight.indirectDiffuse *= ambientOcclusion;

    #if defined(USE_CLEARCOAT) 
    clearcoatSpecularIndirect *= ambientOcclusion;
    #end

    #if defined(USE_SHEEN) 
    sheenSpecularIndirect *= ambientOcclusion;
    #end

    #if defined(USE_ENVMAP) && defined(STANDARD)

    var dotNV:Float = saturate(dot(geometryNormal, geometryViewDir));

    reflectedLight.indirectSpecular *= computeSpecularOcclusion(dotNV, ambientOcclusion, material.roughness);

    #end

    #end
}