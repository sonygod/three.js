package three.js.src.renderers.shaders.ShaderChunk;

class LightsFragmentBegin {
    static var geometryPosition:Vec3;
    static var geometryNormal:Vec3;
    static var geometryViewDir:Vec3;
    static var geometryClearcoatNormal:Vec3;
    static var directLight:IncidentLight;
    static var pointLight:PointLight;
    static var pointLightShadow:PointLightShadow;
    static var spotLight:SpotLight;
    static var spotLightShadow:SpotLightShadow;
    static var directionalLight:DirectionalLight;
    static var directionalLightShadow:DirectionalLightShadow;
    static var rectAreaLight:RectAreaLight;
    static var iblIrradiance:Vec3;
    static var irradiance:Vec3;
    static var radiance:Vec3;
    static var clearcoatRadiance:Vec3;

    static function main() {
        geometryPosition = - vViewPosition;
        geometryNormal = normal;
        geometryViewDir = ( isOrthographic ) ? Vec3( 0, 0, 1 ) : normalize( vViewPosition );

        geometryClearcoatNormal = Vec3( 0.0 );

        #if USE_CLEARCOAT
            geometryClearcoatNormal = clearcoatNormal;
        #end

        #if USE_IRIDESCENCE
            var dotNVi:Float = saturate( dot( normal, geometryViewDir ) );

            if ( material.iridescenceThickness == 0.0 ) {
                material.iridescence = 0.0;
            } else {
                material.iridescence = saturate( material.iridescence );
            }

            if ( material.iridescence > 0.0 ) {
                material.iridescenceFresnel = evalIridescence( 1.0, material.iridescenceIOR, dotNVi, material.iridescenceThickness, material.specularColor );
                // Iridescence F0 approximation
                material.iridescenceF0 = Schlick_to_F0( material.iridescenceFresnel, 1.0, dotNVi );
            }
        #end

        #if ( NUM_POINT_LIGHTS > 0 ) && defined( RE_Direct )
            #pragma unroll_loop_start
            for ( i in 0...NUM_POINT_LIGHTS ) {
                pointLight = pointLights[ i ];
                getPointLightInfo( pointLight, geometryPosition, directLight );
                #if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_POINT_LIGHT_SHADOWS )
                    pointLightShadow = pointLightShadows[ i ];
                    directLight.color *= ( directLight.visible && receiveShadow ) ? getPointShadow( pointShadowMap[ i ], pointLightShadow.shadowMapSize, pointLightShadow.shadowBias, pointLightShadow.shadowRadius, vPointShadowCoord[ i ], pointLightShadow.shadowCameraNear, pointLightShadow.shadowCameraFar ) : 1.0;
                #end
                RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
            }
            #pragma unroll_loop_end
        #end

        #if ( NUM_SPOT_LIGHTS > 0 ) && defined( RE_Direct )
            #pragma unroll_loop_start
            for ( i in 0...NUM_SPOT_LIGHTS ) {
                spotLight = spotLights[ i ];
                getSpotLightInfo( spotLight, geometryPosition, directLight );
                // spot lights are ordered [shadows with maps, shadows without maps, maps without shadows, none]
                #if ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )
                    #define SPOT_LIGHT_MAP_INDEX UNROLLED_LOOP_INDEX
                #elif ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
                    #define SPOT_LIGHT_MAP_INDEX NUM_SPOT_LIGHT_MAPS
                #else
                    #define SPOT_LIGHT_MAP_INDEX ( UNROLLED_LOOP_INDEX - NUM_SPOT_LIGHT_SHADOWS + NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )
                #endif

                #if ( SPOT_LIGHT_MAP_INDEX < NUM_SPOT_LIGHT_MAPS )
                    spotLightCoord = vSpotLightCoord[ i ].xyz / vSpotLightCoord[ i ].w;
                    inSpotLightMap = all( lessThan( abs( spotLightCoord * 2. - 1. ), Vec3( 1.0 ) ) );
                    spotColor = texture2D( spotLightMap[ SPOT_LIGHT_MAP_INDEX ], spotLightCoord.xy );
                    directLight.color = inSpotLightMap ? directLight.color * spotColor.rgb : directLight.color;
                #end

                #undef SPOT_LIGHT_MAP_INDEX

                #if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
                    spotLightShadow = spotLightShadows[ i ];
                    directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( spotShadowMap[ i ], spotLightShadow.shadowMapSize, spotLightShadow.shadowBias, spotLightShadow.shadowRadius, vSpotLightCoord[ i ] ) : 1.0;
                #end

                RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
            }
            #pragma unroll_loop_end
        #end

        #if ( NUM_DIR_LIGHTS > 0 ) && defined( RE_Direct )
            #pragma unroll_loop_start
            for ( i in 0...NUM_DIR_LIGHTS ) {
                directionalLight = directionalLights[ i ];
                getDirectionalLightInfo( directionalLight, directLight );
                #if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_DIR_LIGHT_SHADOWS )
                    directionalLightShadow = directionalLightShadows[ i ];
                    directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( directionalShadowMap[ i ], directionalLightShadow.shadowMapSize, directionalLightShadow.shadowBias, directionalLightShadow.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
                #end
                RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
            }
            #pragma unroll_loop_end
        #end

        #if ( NUM_RECT_AREA_LIGHTS > 0 ) && defined( RE_Direct_RectArea )
            #pragma unroll_loop_start
            for ( i in 0...NUM_RECT_AREA_LIGHTS ) {
                rectAreaLight = rectAreaLights[ i ];
                RE_Direct_RectArea( rectAreaLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
            }
            #pragma unroll_loop_end
        #end

        #if defined( RE_IndirectDiffuse )
            iblIrradiance = Vec3( 0.0 );
            irradiance = getAmbientLightIrradiance( ambientLightColor );
            #if defined( USE_LIGHT_PROBES )
                irradiance += getLightProbeIrradiance( lightProbe, geometryNormal );
            #end
            #if ( NUM_HEMI_LIGHTS > 0 )
                #pragma unroll_loop_start
                for ( i in 0...NUM_HEMI_LIGHTS ) {
                    irradiance += getHemisphereLightIrradiance( hemisphereLights[ i ], geometryNormal );
                }
                #pragma unroll_loop_end
            #end
        #end

        #if defined( RE_IndirectSpecular )
            radiance = Vec3( 0.0 );
            clearcoatRadiance = Vec3( 0.0 );
        #end
    }
}