package three.js.src.renderers.shaders.ShaderChunk;

class shadowmap_vertex {
    static var fragment = "#if ( defined( USE_SHADOWMAP ) && ( NUM_DIR_LIGHT_SHADOWS > 0 || NUM_POINT_LIGHT_SHADOWS > 0 ) ) || ( NUM_SPOT_LIGHT_COORDS > 0 )\n\n" +
        "    // Offsetting the position used for querying occlusion along the world normal can be used to reduce shadow acne.\n" +
        "    vec3 shadowWorldNormal = inverseTransformDirection( transformedNormal, viewMatrix );\n" +
        "    vec4 shadowWorldPosition;\n\n" +
        "#endif\n\n" +
        "#if defined( USE_SHADOWMAP )\n\n" +
        "    #if NUM_DIR_LIGHT_SHADOWS > 0\n\n" +
        "        #pragma unroll_loop_start\n" +
        "        for ( int i = 0; i < NUM_DIR_LIGHT_SHADOWS; i ++ ) {\n\n" +
        "            shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * directionalLightShadows[ i ].shadowNormalBias, 0 );\n" +
        "            vDirectionalShadowCoord[ i ] = directionalShadowMatrix[ i ] * shadowWorldPosition;\n\n" +
        "        }\n" +
        "        #pragma unroll_loop_end\n\n" +
        "    #endif\n\n" +
        "    #if NUM_POINT_LIGHT_SHADOWS > 0\n\n" +
        "        #pragma unroll_loop_start\n" +
        "        for ( int i = 0; i < NUM_POINT_LIGHT_SHADOWS; i ++ ) {\n\n" +
        "            shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * pointLightShadows[ i ].shadowNormalBias, 0 );\n" +
        "            vPointShadowCoord[ i ] = pointShadowMatrix[ i ] * shadowWorldPosition;\n\n" +
        "        }\n" +
        "        #pragma unroll_loop_end\n\n" +
        "    #endif\n\n" +
        "    /*\n" +
        "    #if NUM_RECT_AREA_LIGHTS > 0\n\n" +
        "        // TODO (abelnation): update vAreaShadowCoord with area light info\n\n" +
        "    #endif\n" +
        "    */\n\n" +
        "#endif\n\n" +
        "// spot lights can be evaluated without active shadow mapping (when SpotLight.map is used)\n\n" +
        "#if NUM_SPOT_LIGHT_COORDS > 0\n\n" +
        "    #pragma unroll_loop_start\n" +
        "    for ( int i = 0; i < NUM_SPOT_LIGHT_COORDS; i ++ ) {\n\n" +
        "        shadowWorldPosition = worldPosition;\n" +
        "        #if ( defined( USE_SHADOWMAP ) && UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )\n" +
        "            shadowWorldPosition.xyz += shadowWorldNormal * spotLightShadows[ i ].shadowNormalBias;\n" +
        "        #endif\n" +
        "        vSpotLightCoord[ i ] = spotLightMatrix[ i ] * shadowWorldPosition;\n\n" +
        "    }\n" +
        "    #pragma unroll_loop_end\n\n" +
        "#endif";
}