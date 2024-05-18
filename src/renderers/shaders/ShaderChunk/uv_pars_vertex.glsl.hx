package three.shader;

#if (use_uv || use_anisotropy)
    @:GLSL("varying vec2 vUv;")
#end

#if use_map
    @:GLSL("uniform mat3 mapTransform;
            varying vec2 vMapUv;")
#end

#if use_alphamap
    @:GLSL("uniform mat3 alphaMapTransform;
            varying vec2 vAlphaMapUv;")
#end

#if use_lightmap
    @:GLSL("uniform mat3 lightMapTransform;
            varying vec2 vLightMapUv;")
#end

#if use_aomap
    @:GLSL("uniform mat3 aoMapTransform;
            varying vec2 vAoMapUv;")
#end

#if use_bumpmap
    @:GLSL("uniform mat3 bumpMapTransform;
            varying vec2 vBumpMapUv;")
#end

#if use_normalmap
    @:GLSL("uniform mat3 normalMapTransform;
            varying vec2 vNormalMapUv;")
#end

#if use_displacementmap
    @:GLSL("uniform mat3 displacementMapTransform;
            varying vec2 vDisplacementMapUv;")
#end

#if use_emissivemap
    @:GLSL("uniform mat3 emissiveMapTransform;
            varying vec2 vEmissiveMapUv;")
#end

#if use_metalnessmap
    @:GLSL("uniform mat3 metalnessMapTransform;
            varying vec2 vMetalnessMapUv;")
#end

#if use_roughnessmap
    @:GLSL("uniform mat3 roughnessMapTransform;
            varying vec2 vRoughnessMapUv;")
#end

#if use_anisotropymap
    @:GLSL("uniform mat3 anisotropyMapTransform;
            varying vec2 vAnisotropyMapUv;")
#end

#if use_clearcoatmap
    @:GLSL("uniform mat3 clearcoatMapTransform;
            varying vec2 vClearcoatMapUv;")
#end

#if use_clearcoat_normalmap
    @:GLSL("uniform mat3 clearcoatNormalMapTransform;
            varying vec2 vClearcoatNormalMapUv;")
#end

#if use_clearcoat_roughnessmap
    @:GLSL("uniform mat3 clearcoatRoughnessMapTransform;
            varying vec2 vClearcoatRoughnessMapUv;")
#end

#if use_sheen_colormap
    @:GLSL("uniform mat3 sheenColorMapTransform;
            varying vec2 vSheenColorMapUv;")
#end

#if use_sheen_roughnessmap
    @:GLSL("uniform mat3 sheenRoughnessMapTransform;
            varying vec2 vSheenRoughnessMapUv;")
#end

#if use_iridescencemap
    @:GLSL("uniform mat3 iridescenceMapTransform;
            varying vec2 vIridescenceMapUv;")
#end

#if use_iridescence_thicknessmap
    @:GLSL("uniform mat3 iridescenceThicknessMapTransform;
            varying vec2 vIridescenceThicknessMapUv;")
#end

#if use_specularmap
    @:GLSL("uniform mat3 specularMapTransform;
            varying vec2 vSpecularMapUv;")
#end

#if use_specular_colormap
    @:GLSL("uniform mat3 specularColorMapTransform;
            varying vec2 vSpecularColorMapUv;")
#end

#if use_specular_intensitymap
    @:GLSL("uniform mat3 specularIntensityMapTransform;
            varying vec2 vSpecularIntensityMapUv;")
#end

#if use_transmissionmap
    @:GLSL("uniform mat3 transmissionMapTransform;
            varying vec2 vTransmissionMapUv;")
#end

#if use_thicknessmap
    @:GLSL("uniform mat3 thicknessMapTransform;
            varying vec2 vThicknessMapUv;")
#end