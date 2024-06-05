package three.js.src.renderers.shaders.ShaderChunk;

class uv_vertex {
    static var uv_vertex = "#if defined( USE_UV ) || defined( USE_ANISOTROPY )\n\n" +
        "\tvUv = vec3( uv, 1 ).xy;\n\n" +
        "#endif\n#ifdef USE_MAP\n\n" +
        "\tvMapUv = ( mapTransform * vec3( MAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_ALPHAMAP\n\n" +
        "\tvAlphaMapUv = ( alphaMapTransform * vec3( ALPHAMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_LIGHTMAP\n\n" +
        "\tvLightMapUv = ( lightMapTransform * vec3( LIGHTMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_AOMAP\n\n" +
        "\tvAoMapUv = ( aoMapTransform * vec3( AOMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_BUMPMAP\n\n" +
        "\tvBumpMapUv = ( bumpMapTransform * vec3( BUMPMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_NORMALMAP\n\n" +
        "\tvNormalMapUv = ( normalMapTransform * vec3( NORMALMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_DISPLACEMENTMAP\n\n" +
        "\tvDisplacementMapUv = ( displacementMapTransform * vec3( DISPLACEMENTMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_EMISSIVEMAP\n\n" +
        "\tvEmissiveMapUv = ( emissiveMapTransform * vec3( EMISSIVEMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_METALNESSMAP\n\n" +
        "\tvMetalnessMapUv = ( metalnessMapTransform * vec3( METALNESSMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_ROUGHNESSMAP\n\n" +
        "\tvRoughnessMapUv = ( roughnessMapTransform * vec3( ROUGHNESSMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_ANISOTROPYMAP\n\n" +
        "\tvAnisotropyMapUv = ( anisotropyMapTransform * vec3( ANISOTROPYMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_CLEARCOATMAP\n\n" +
        "\tvClearcoatMapUv = ( clearcoatMapTransform * vec3( CLEARCOATMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_CLEARCOAT_NORMALMAP\n\n" +
        "\tvClearcoatNormalMapUv = ( clearcoatNormalMapTransform * vec3( CLEARCOAT_NORMALMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_CLEARCOAT_ROUGHNESSMAP\n\n" +
        "\tvClearcoatRoughnessMapUv = ( clearcoatRoughnessMapTransform * vec3( CLEARCOAT_ROUGHNESSMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_IRIDESCENCEMAP\n\n" +
        "\tvIridescenceMapUv = ( iridescenceMapTransform * vec3( IRIDESCENCEMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_IRIDESCENCE_THICKNESSMAP\n\n" +
        "\tvIridescenceThicknessMapUv = ( iridescenceThicknessMapTransform * vec3( IRIDESCENCE_THICKNESSMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_SHEEN_COLORMAP\n\n" +
        "\tvSheenColorMapUv = ( sheenColorMapTransform * vec3( SHEEN_COLORMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_SHEEN_ROUGHNESSMAP\n\n" +
        "\tvSheenRoughnessMapUv = ( sheenRoughnessMapTransform * vec3( SHEEN_ROUGHNESSMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_SPECULARMAP\n\n" +
        "\tvSpecularMapUv = ( specularMapTransform * vec3( SPECULARMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_SPECULAR_COLORMAP\n\n" +
        "\tvSpecularColorMapUv = ( specularColorMapTransform * vec3( SPECULAR_COLORMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_SPECULAR_INTENSITYMAP\n\n" +
        "\tvSpecularIntensityMapUv = ( specularIntensityMapTransform * vec3( SPECULAR_INTENSITYMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_TRANSMISSIONMAP\n\n" +
        "\tvTransmissionMapUv = ( transmissionMapTransform * vec3( TRANSMISSIONMAP_UV, 1 ) ).xy;\n\n" +
        "#endif\n#ifdef USE_THICKNESSMAP\n\n" +
        "\tvThicknessMapUv = ( thicknessMapTransform * vec3( THICKNESSMAP_UV, 1 ) ).xy;\n\n" +
        "#endif";
}