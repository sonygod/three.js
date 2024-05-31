class Main {
  public static function main(): Void {
    
    var glsl: String = /* glsl */
    /**
     * This is a template that can be used to light a material, it uses pluggable
     * RenderEquations (RE)for specific lighting scenarios.
     *
     * Instructions for use:
     * - Ensure that both RE_Direct, RE_IndirectDiffuse and RE_IndirectSpecular are defined
     * - Create a material parameter that is to be passed as the third parameter to your lighting functions.
     *
     * TODO:
     * - Add area light support.
     * - Add sphere light support.
     * - Add diffuse light probe (irradiance cubemap) support.
     */

    "vec3 geometryPosition = - vViewPosition;\n" +
    "vec3 geometryNormal = normal;\n" +
    "vec3 geometryViewDir = ( isOrthographic ) ? vec3( 0, 0, 1 ) : normalize( vViewPosition );\n" +
    
    "vec3 geometryClearcoatNormal = vec3( 0.0 );\n" +
    
    "#ifdef USE_CLEARCOAT\n" +
    
    "\tgeometryClearcoatNormal = clearcoatNormal;\n" +
    
    "#endif\n" +
    
    "#ifdef USE_IRIDESCENCE\n" +
    
    "\tfloat dotNVi = saturate( dot( normal, geometryViewDir ) );\n" +
    
    "\tif ( material.iridescenceThickness == 0.0 ) {\n" +
    
    "\t\tmaterial.iridescence = 0.0;\n" +
    
    "\t} else {\n" +
    
    "\t\tmaterial.iridescence = saturate( material.iridescence );\n" +
    
    "\t}\n" +
    
    "\tif ( material.iridescence > 0.0 ) {\n" +
    
    "\t\tmaterial.iridescenceFresnel = evalIridescence( 1.0, material.iridescenceIOR, dotNVi, material.iridescenceThickness, material.specularColor );\n" +
    
    "\t\t// Iridescence F0 approximation\n" +
    "\t\tmaterial.iridescenceF0 = Schlick_to_F0( material.iridescenceFresnel, 1.0, dotNVi );\n" +
    
    "\t}\n" +
    
    "#endif\n" +
    
    "IncidentLight directLight;\n" +
    
    "#if ( NUM_POINT_LIGHTS > 0 ) && defined( RE_Direct )\n" +
    
    "\tPointLight pointLight;\n" +
    "\t#if defined( USE_SHADOWMAP ) && NUM_POINT_LIGHT_SHADOWS > 0\n" +
    "\tPointLightShadow pointLightShadow;\n" +
    "\t#endif\n" +
    
    "\t#pragma unroll_loop_start\n" +
    "\tfor ( int i = 0; i < NUM_POINT_LIGHTS; i ++ ) {\n" +
    
    "\t\tpointLight = pointLights[ i ];\n" +
    
    "\t\tgetPointLightInfo( pointLight, geometryPosition, directLight );\n" +
    
    "\t\t#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_POINT_LIGHT_SHADOWS )\n" +
    "\t\tpointLightShadow = pointLightShadows[ i ];\n" +
    "\t\tdirectLight.color *= ( directLight.visible && receiveShadow ) ? getPointShadow( pointShadowMap[ i ], pointLightShadow.shadowMapSize, pointLightShadow.shadowBias, pointLightShadow.shadowRadius, vPointShadowCoord[ i ], pointLightShadow.shadowCameraNear, pointLightShadow.shadowCameraFar ) : 1.0;\n" +
    "\t\t#endif\n" +
    
    "\t\tRE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );\n" +
    
    "\t}\n" +
    "\t#pragma unroll_loop_end\n" +
    
    "#endif\n" +
    
    "#if ( NUM_SPOT_LIGHTS > 0 ) && defined( RE_Direct )\n" +
    
    "\tSpotLight spotLight;\n" +
    "\tvec4 spotColor;\n" +
    "\tvec3 spotLightCoord;\n" +
    "\tbool inSpotLightMap;\n" +
    
    "\t#if defined( USE_SHADOWMAP ) && NUM_SPOT_LIGHT_SHADOWS > 0\n" +
    "\tSpotLightShadow spotLightShadow;\n" +
    "\t#endif\n" +
    
    "\t#pragma unroll_loop_start\n" +
    "\tfor ( int i = 0; i < NUM_SPOT_LIGHTS; i ++ ) {\n" +
    
    "\t\tspotLight = spotLights[ i ];\n" +
    
    "\t\tgetSpotLightInfo( spotLight, geometryPosition, directLight );\n" +
    
    "\t\t// spot lights are ordered [shadows with maps, shadows without maps, maps without shadows, none]\n" +
    "\t\t#if ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )\n" +
    "\t\t#define SPOT_LIGHT_MAP_INDEX UNROLLED_LOOP_INDEX\n" +
    "\t\t#elif ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )\n" +
    "\t\t#define SPOT_LIGHT_MAP_INDEX NUM_SPOT_LIGHT_MAPS\n" +
    "\t\t#else\n" +
    "\t\t#define SPOT_LIGHT_MAP_INDEX ( UNROLLED_LOOP_INDEX - NUM_SPOT_LIGHT_SHADOWS + NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )\n" +
    "\t\t#endif\n" +
    
    "\t\t#if ( SPOT_LIGHT_MAP_INDEX < NUM_SPOT_LIGHT_MAPS )\n" +
    "\t\t\tspotLightCoord = vSpotLightCoord[ i ].xyz / vSpotLightCoord[ i ].w;\n" +
    "\t\t\tinSpotLightMap = all( lessThan( abs( spotLightCoord * 2. - 1. ), vec3( 1.0 ) ) );\n" +
    "\t\t\tspotColor = texture2D( spotLightMap[ SPOT_LIGHT_MAP_INDEX ], spotLightCoord.xy );\n" +
    "\t\t\tdirectLight.color = inSpotLightMap ? directLight.color * spotColor.rgb : directLight.color;\n" +
    "\t\t#endif\n" +
    
    "\t\t#undef SPOT_LIGHT_MAP_INDEX\n" +
    
    "\t\t#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )\n" +
    "\t\tspotLightShadow = spotLightShadows[ i ];\n" +
    "\t\tdirectLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( spotShadowMap[ i ], spotLightShadow.shadowMapSize, spotLightShadow.shadowBias, spotLightShadow.shadowRadius, vSpotLightCoord[ i ] ) : 1.0;\n" +
    "\t\t#endif\n" +
    
    "\t\tRE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );\n" +
    
    "\t}\n" +
    "\t#pragma unroll_loop_end\n" +
    
    "#endif\n" +
    
    "#if ( NUM_DIR_LIGHTS > 0 ) && defined( RE_Direct )\n" +
    
    "\tDirectionalLight directionalLight;\n" +
    "\t#if defined( USE_SHADOWMAP ) && NUM_DIR_LIGHT_SHADOWS > 0\n" +
    "\tDirectionalLightShadow directionalLightShadow;\n" +
    "\t#endif\n" +
    
    "\t#pragma unroll_loop_start\n" +
    "\tfor ( int i = 0; i < NUM_DIR_LIGHTS; i ++ ) {\n" +
    
    "\t\tdirectionalLight = directionalLights[ i ];\n" +
    
    "\t\tgetDirectionalLightInfo( directionalLight, directLight );\n" +
    
    "\t\t#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_DIR_LIGHT_SHADOWS )\n" +
    "\t\tdirectionalLightShadow = directionalLightShadows[ i ];\n" +
    "\t\tdirectLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( directionalShadowMap[ i ], directionalLightShadow.shadowMapSize, directionalLightShadow.shadowBias, directionalLightShadow.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;\n" +
    "\t\t#endif\n" +
    
    "\t\tRE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );\n" +
    
    "\t}\n" +
    "\t#pragma unroll_loop_end\n" +
    
    "#endif\n" +
    
    "#if ( NUM_RECT_AREA_LIGHTS > 0 ) && defined( RE_Direct_RectArea )\n" +
    
    "\tRectAreaLight rectAreaLight;\n" +
    
    "\t#pragma unroll_loop_start\n" +
    "\tfor ( int i = 0; i < NUM_RECT_AREA_LIGHTS; i ++ ) {\n" +
    
    "\t\trectAreaLight = rectAreaLights[ i ];\n" +
    "\t\tRE_Direct_RectArea( rectAreaLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );\n" +
    
    "\t}\n" +
    "\t#pragma unroll_loop_end\n" +
    
    "#endif\n" +
    
    "#if defined( RE_IndirectDiffuse )\n" +
    
    "\tvec3 iblIrradiance = vec3( 0.0 );\n" +
    
    "\tvec3 irradiance = getAmbientLightIrradiance( ambientLightColor );\n" +
    
    "\t#if defined( USE_LIGHT_PROBES )\n" +
    
    "\t\tirradiance += getLightProbeIrradiance( lightProbe, geometryNormal );\n" +
    
    "\t#endif\n" +
    
    "\t#if ( NUM_HEMI_LIGHTS > 0 )\n" +
    
    "\t\t#pragma unroll_loop_start\n" +
    "\t\tfor ( int i = 0; i < NUM_HEMI_LIGHTS; i ++ ) {\n" +
    
    "\t\t\tirradiance += getHemisphereLightIrradiance( hemisphereLights[ i ], geometryNormal );\n" +
    
    "\t\t}\n" +
    "\t\t#pragma unroll_loop_end\n" +
    
    "\t#endif\n" +
    
    "#endif\n" +
    
    "#if defined( RE_IndirectSpecular )\n" +
    
    "\tvec3 radiance = vec3( 0.0 );\n" +
    "\tvec3 clearcoatRadiance = vec3( 0.0 );\n" +
    
    "#endif\n";

  }
}