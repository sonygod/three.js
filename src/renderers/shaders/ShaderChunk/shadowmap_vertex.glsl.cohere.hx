#if ( defined( USE_SHADOWMAP ) && ( NUM_DIR_LIGHT_SHADOWS > 0 || NUM_POINT_LIGHT_SHADOWS > 0 ) ) || ( NUM_SPOT_LIGHT_COORDS > 0 )

	// Offsetting the position used for querying occlusion along the world normal can be used to reduce shadow acne.
	var shadowWorldNormal = inverseTransformDirection( transformedNormal, viewMatrix );
	var shadowWorldPosition:Vec4;

#endif

#if defined( USE_SHADOWMAP )

	#if NUM_DIR_LIGHT_SHADOWS > 0

		#pragma unroll_loop_start
		for ( i in 0...NUM_DIR_LIGHT_SHADOWS ) {

			shadowWorldPosition = worldPosition + Vec4( shadowWorldNormal * directionalLightShadows[i].shadowNormalBias, 0.0 );
			vDirectionalShadowCoord[i] = directionalShadowMatrix[i] * shadowWorldPosition;

		}
		#pragma unroll_loop_end

	#endif

	#if NUM_POINT_LIGHT_SHADOWS > 0

		#pragma unroll_loop_start
		for ( i in 0...NUM_POINT_LIGHT_SHADOWS ) {

			shadowWorldPosition = worldPosition + Vec4( shadowWorldNormal * pointLightShadows[i].shadowNormalBias, 0.0 );
			vPointShadowCoord[i] = pointShadowMatrix[i] * shadowWorldPosition;

		}
		#pragma unroll_loop_end

	#endif

	/*
	#if NUM_RECT_AREA_LIGHTS > 0

		// TODO (abelnation): update vAreaShadowCoord with area light info

	#endif
	*/

#endif

// spot lights can be evaluated without active shadow mapping (when SpotLight.map is used)

#if NUM_SPOT_LIGHT_COORDS > 0

	#pragma unroll_loop_start
	for ( i in 0...NUM_SPOT_LIGHT_COORDS ) {

		shadowWorldPosition = worldPosition;
		#if ( defined( USE_SHADOWMAP ) && UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
			shadowWorldPosition.xyz += shadowWorldNormal * spotLightShadows[i].shadowNormalBias;
		#endif
		vSpotLightCoord[i] = spotLightMatrix[i] * shadowWorldPosition;

	}
	#pragma unroll_loop_end

#endif