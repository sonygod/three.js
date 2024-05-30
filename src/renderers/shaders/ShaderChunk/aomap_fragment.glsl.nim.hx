package three.js.src.renderers.shaders.ShaderChunk;

@:build(macro.ShaderChunkMacro.build("aomap_fragment.glsl"))
class AomapFragment {
    static var fragmentShader =
#ifdef USE_AOMAP

	// reads channel R, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
	"	float ambientOcclusion = ( texture2D( aoMap, vAoMapUv ).r - 1.0 ) * aoMapIntensity + 1.0;\n" +

	"	reflectedLight.indirectDiffuse *= ambientOcclusion;\n" +

	#if defined( USE_CLEARCOAT )
		"	clearcoatSpecularIndirect *= ambientOcclusion;\n" +
	#end

	#if defined( USE_SHEEN )
		"	sheenSpecularIndirect *= ambientOcclusion;\n" +
	#end

	#if defined( USE_ENVMAP ) && defined( STANDARD )

		"	float dotNV = saturate( dot( geometryNormal, geometryViewDir ) );\n" +

		"	reflectedLight.indirectSpecular *= computeSpecularOcclusion( dotNV, ambientOcclusion, material.roughness );\n" +

	#end

#end
    ;
}