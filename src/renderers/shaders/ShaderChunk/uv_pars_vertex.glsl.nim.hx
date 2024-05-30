package three.renderers.shaders.ShaderChunk;

class uv_pars_vertex {
	#if defined(USE_UV) || defined(USE_ANISOTROPY)
		var vUv:Float32Array;
	#end
	#if defined(USE_MAP)
		var mapTransform:Float32Array;
		var vMapUv:Float32Array;
	#end
	#if defined(USE_ALPHAMAP)
		var alphaMapTransform:Float32Array;
		var vAlphaMapUv:Float32Array;
	#end
	#if defined(USE_LIGHTMAP)
		var lightMapTransform:Float32Array;
		var vLightMapUv:Float32Array;
	#end
	#if defined(USE_AOMAP)
		var aoMapTransform:Float32Array;
		var vAoMapUv:Float32Array;
	#end
	#if defined(USE_BUMPMAP)
		var bumpMapTransform:Float32Array;
		var vBumpMapUv:Float32Array;
	#end
	#if defined(USE_NORMALMAP)
		var normalMapTransform:Float32Array;
		var vNormalMapUv:Float32Array;
	#end
	#if defined(USE_DISPLACEMENTMAP)
		var displacementMapTransform:Float32Array;
		var vDisplacementMapUv:Float32Array;
	#end
	#if defined(USE_EMISSIVEMAP)
		var emissiveMapTransform:Float32Array;
		var vEmissiveMapUv:Float32Array;
	#end
	#if defined(USE_METALNESSMAP)
		var metalnessMapTransform:Float32Array;
		var vMetalnessMapUv:Float32Array;
	#end
	#if defined(USE_ROUGHNESSMAP)
		var roughnessMapTransform:Float32Array;
		var vRoughnessMapUv:Float32Array;
	#end
	#if defined(USE_ANISOTROPYMAP)
		var anisotropyMapTransform:Float32Array;
		var vAnisotropyMapUv:Float32Array;
	#end
	#if defined(USE_CLEARCOATMAP)
		var clearcoatMapTransform:Float32Array;
		var vClearcoatMapUv:Float32Array;
	#end
	#if defined(USE_CLEARCOAT_NORMALMAP)
		var clearcoatNormalMapTransform:Float32Array;
		var vClearcoatNormalMapUv:Float32Array;
	#end
	#if defined(USE_CLEARCOAT_ROUGHNESSMAP)
		var clearcoatRoughnessMapTransform:Float32Array;
		var vClearcoatRoughnessMapUv:Float32Array;
	#end
	#if defined(USE_SHEEN_COLORMAP)
		var sheenColorMapTransform:Float32Array;
		var vSheenColorMapUv:Float32Array;
	#end
	#if defined(USE_SHEEN_ROUGHNESSMAP)
		var sheenRoughnessMapTransform:Float32Array;
		var vSheenRoughnessMapUv:Float32Array;
	#end
	#if defined(USE_IRIDESCENCEMAP)
		var iridescenceMapTransform:Float32Array;
		var vIridescenceMapUv:Float32Array;
	#end
	#if defined(USE_IRIDESCENCE_THICKNESSMAP)
		var iridescenceThicknessMapTransform:Float32Array;
		var vIridescenceThicknessMapUv:Float32Array;
	#end
	#if defined(USE_SPECULARMAP)
		var specularMapTransform:Float32Array;
		var vSpecularMapUv:Float32Array;
	#end
	#if defined(USE_SPECULAR_COLORMAP)
		var specularColorMapTransform:Float32Array;
		var vSpecularColorMapUv:Float32Array;
	#end
	#if defined(USE_SPECULAR_INTENSITYMAP)
		var specularIntensityMapTransform:Float32Array;
		var vSpecularIntensityMapUv:Float32Array;
	#end
	#if defined(USE_TRANSMISSIONMAP)
		var transmissionMapTransform:Float32Array;
		var vTransmissionMapUv:Float32Array;
	#end
	#if defined(USE_THICKNESSMAP)
		var thicknessMapTransform:Float32Array;
		var vThicknessMapUv:Float32Array;
	#end
}