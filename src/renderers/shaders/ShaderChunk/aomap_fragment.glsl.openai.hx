package three.renderers.shaders.ShaderChunk;

class AOMapFragment {
    public function new() {}

    #if USE_AOMAP

        var ambientOcclusion:Float = (texture2D(aoMap, vAoMapUv).r - 1.0) * aoMapIntensity + 1.0;

        reflectedLight.indirectDiffuse *= ambientOcclusion;

        #if USE_CLEARCOAT
            clearcoatSpecularIndirect *= ambientOcclusion;
        #end

        #if USE_SHEEN
            sheenSpecularIndirect *= ambientOcclusion;
        #end

        #if USE_ENVMAP && STANDARD

            var dotNV:Float = saturate(dot(geometryNormal, geometryViewDir));

            reflectedLight.indirectSpecular *= computeSpecularOcclusion(dotNV, ambientOcclusion, material.roughness);

        #end

    #end
}