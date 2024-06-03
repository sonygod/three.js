// haxe

class ShaderChunkUVParsVertex {
    public static function getShaderCode():String {
        return """
#if defined( USE_UV ) || defined( USE_ANISOTROPY )

	var vUv:Vec2;

#endif
#ifdef USE_MAP

	var mapTransform:Mat3;
	var vMapUv:Vec2;

#endif
#ifdef USE_ALPHAMAP

	var alphaMapTransform:Mat3;
	var vAlphaMapUv:Vec2;

#endif
#ifdef USE_LIGHTMAP

	var lightMapTransform:Mat3;
	var vLightMapUv:Vec2;

#endif
#ifdef USE_AOMAP

	var aoMapTransform:Mat3;
	var vAoMapUv:Vec2;

#endif
#ifdef USE_BUMPMAP

	var bumpMapTransform:Mat3;
	var vBumpMapUv:Vec2;

#endif
#ifdef USE_NORMALMAP

	var normalMapTransform:Mat3;
	var vNormalMapUv:Vec2;

#endif
#ifdef USE_DISPLACEMENTMAP

	var displacementMapTransform:Mat3;
	var vDisplacementMapUv:Vec2;

#endif
#ifdef USE_EMISSIVEMAP

	var emissiveMapTransform:Mat3;
	var vEmissiveMapUv:Vec2;

#endif
#ifdef USE_METALNESSMAP

	var metalnessMapTransform:Mat3;
	var vMetalnessMapUv:Vec2;

#endif
#ifdef USE_ROUGHNESSMAP

	var roughnessMapTransform:Mat3;
	var vRoughnessMapUv:Vec2;

#endif
#ifdef USE_ANISOTROPYMAP

	var anisotropyMapTransform:Mat3;
	var vAnisotropyMapUv:Vec2;

#endif
#ifdef USE_CLEARCOATMAP

	var clearcoatMapTransform:Mat3;
	var vClearcoatMapUv:Vec2;

#endif
#ifdef USE_CLEARCOAT_NORMALMAP

	var clearcoatNormalMapTransform:Mat3;
	var vClearcoatNormalMapUv:Vec2;

#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP

	var clearcoatRoughnessMapTransform:Mat3;
	var vClearcoatRoughnessMapUv:Vec2;

#endif
#ifdef USE_SHEEN_COLORMAP

	var sheenColorMapTransform:Mat3;
	var vSheenColorMapUv:Vec2;

#endif
#ifdef USE_SHEEN_ROUGHNESSMAP

	var sheenRoughnessMapTransform:Mat3;
	var vSheenRoughnessMapUv:Vec2;

#endif
#ifdef USE_IRIDESCENCEMAP

	var iridescenceMapTransform:Mat3;
	var vIridescenceMapUv:Vec2;

#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP

	var iridescenceThicknessMapTransform:Mat3;
	var vIridescenceThicknessMapUv:Vec2;

#endif
#ifdef USE_SPECULARMAP

	var specularMapTransform:Mat3;
	var vSpecularMapUv:Vec2;

#endif
#ifdef USE_SPECULAR_COLORMAP

	var specularColorMapTransform:Mat3;
	var vSpecularColorMapUv:Vec2;

#endif
#ifdef USE_SPECULAR_INTENSITYMAP

	var specularIntensityMapTransform:Mat3;
	var vSpecularIntensityMapUv:Vec2;

#endif
#ifdef USE_TRANSMISSIONMAP

	var transmissionMapTransform:Mat3;
	var vTransmissionMapUv:Vec2;

#endif
#ifdef USE_THICKNESSMAP

	var thicknessMapTransform:Mat3;
	var vThicknessMapUv:Vec2;

#endif
""";
    }
}