#if defined(USE_AOMAP)

// reads channel R, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
var ambientOcclusion:Float = (tex2D(aoMap, vAoMapUv).r - 1.0) * aoMapIntensity + 1.0;

reflectedLight.indirectDiffuse *= ambientOcclusion;

#if defined(USE_CLEARCOAT)
    clearcoatSpecularIndirect *= ambientOcclusion;
#end

#if defined(USE_SHEEN)
    sheenSpecularIndirect *= ambientOcclusion;
#end

#if defined(USE_ENVMAP) && defined(STANDARD)

    var dotNV:Float = Math.max(0.0, Math.min(1.0, dot(geometryNormal, geometryViewDir)));

    reflectedLight.indirectSpecular *= computeSpecularOcclusion(dotNV, ambientOcclusion, material.roughness);

#end

#end