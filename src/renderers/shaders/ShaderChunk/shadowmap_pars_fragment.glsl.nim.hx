package three.src.renderers.shaders.ShaderChunk;

#if NUM_SPOT_LIGHT_COORDS > 0

	@:glsl(varying) var vSpotLightCoord:Array<Float32Array>;

#end

#if NUM_SPOT_LIGHT_MAPS > 0

	@:glsl(uniform) var spotLightMap:Array<DynamicTexture>;

#end

#if USE_SHADOWMAP

	#if NUM_DIR_LIGHT_SHADOWS > 0

		@:glsl(uniform) var directionalShadowMap:Array<DynamicTexture>;
		@:glsl(varying) var vDirectionalShadowCoord:Array<Float32Array>;

		struct DirectionalLightShadow {
			var shadowBias:Float;
			var shadowNormalBias:Float;
			var shadowRadius:Float;
			var shadowMapSize:Float32Array;
		}

		@:glsl(uniform) var directionalLightShadows:Array<DirectionalLightShadow>;

	#end

	#if NUM_SPOT_LIGHT_SHADOWS > 0

		@:glsl(uniform) var spotShadowMap:Array<DynamicTexture>;

		struct SpotLightShadow {
			var shadowBias:Float;
			var shadowNormalBias:Float;
			var shadowRadius:Float;
			var shadowMapSize:Float32Array;
		}

		@:glsl(uniform) var spotLightShadows:Array<SpotLightShadow>;

	#end

	#if NUM_POINT_LIGHT_SHADOWS > 0

		@:glsl(uniform) var pointShadowMap:Array<DynamicTexture>;
		@:glsl(varying) var vPointShadowCoord:Array<Float32Array>;

		struct PointLightShadow {
			var shadowBias:Float;
			var shadowNormalBias:Float;
			var shadowRadius:Float;
			var shadowMapSize:Float32Array;
			var shadowCameraNear:Float;
			var shadowCameraFar:Float;
		}

		@:glsl(uniform) var pointLightShadows:Array<PointLightShadow>;

	#end

	function texture2DCompare( depths:DynamicTexture, uv:Float32Array, compare:Float ):Float {

		return step( compare, unpackRGBAToDepth( texture2D( depths, uv ) ) );

	}

	function texture2DDistribution( shadow:DynamicTexture, uv:Float32Array ):Float32Array {

		return unpackRGBATo2Half( texture2D( shadow, uv ) );

	}

	function VSMShadow (shadow:DynamicTexture, uv:Float32Array, compare:Float ):Float {

		var occlusion:Float = 1.0;

		var distribution:Float32Array = texture2DDistribution( shadow, uv );

		var hard_shadow:Float = step( compare , distribution[0] ); // Hard Shadow

		if (hard_shadow != 1.0 ) {

			var distance:Float = compare - distribution[0];
			var variance:Float = max( 0.00000, distribution[1] * distribution[1] );
			var softness_probability:Float = variance / (variance + distance * distance ); // Chebeyshevs inequality
			softness_probability = clamp( ( softness_probability - 0.3 ) / ( 0.95 - 0.3 ), 0.0, 1.0 ); // 0.3 reduces light bleed
			occlusion = clamp( max( hard_shadow, softness_probability ), 0.0, 1.0 );

		}
		return occlusion;

	}

	function getShadow( shadowMap:DynamicTexture, shadowMapSize:Float32Array, shadowBias:Float, shadowRadius:Float, shadowCoord:Float32Array ):Float {

		var shadow:Float = 1.0;

		shadowCoord[0] /= shadowCoord[3];
		shadowCoord[1] /= shadowCoord[3];
		shadowCoord[2] /= shadowCoord[3];
		shadowCoord[2] += shadowBias;

		var inFrustum:Bool = shadowCoord[0] >= 0.0 && shadowCoord[0] <= 1.0 && shadowCoord[1] >= 0.0 && shadowCoord[1] <= 1.0;
		var frustumTest:Bool = inFrustum && shadowCoord[2] <= 1.0;

		if ( frustumTest ) {

		#if defined( SHADOWMAP_TYPE_PCF )

			var texelSize:Float32Array = vec2( 1.0 ) / shadowMapSize;

			var dx0:Float = - texelSize[0] * shadowRadius;
			var dy0:Float = - texelSize[1] * shadowRadius;
			var dx1:Float = + texelSize[0] * shadowRadius;
			var dy1:Float = + texelSize[1] * shadowRadius;
			var dx2:Float = dx0 / 2.0;
			var dy2:Float = dy0 / 2.0;
			var dx3:Float = dx1 / 2.0;
			var dy3:Float = dy1 / 2.0;

			shadow = (
				texture2DCompare( shadowMap, vec2( shadowCoord[0] + dx0, shadowCoord[1] + dy0 ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( shadowCoord[0], shadowCoord[1] + dy0 ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( shadowCoord[0] + dx1, shadowCoord[1] + dy0 ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( shadowCoord[0] + dx2, shadowCoord[1] + dy2 ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( shadowCoord[0], shadowCoord[1] + dy2 ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( shadowCoord[0] + dx3, shadowCoord[1] + dy2 ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( shadowCoord[0] + dx0, shadowCoord[1] ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( shadowCoord[0] + dx2, shadowCoord[1] ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( shadowCoord[0], shadowCoord[1] ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( shadowCoord[0] + dx3, shadowCoord[1] ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( shadowCoord[0] + dx1, shadowCoord[1] ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( shadowCoord[0] + dx2, shadowCoord[1] + dy3 ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( shadowCoord[0], shadowCoord[1] + dy3 ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( shadowCoord[0] + dx3, shadowCoord[1] + dy3 ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( shadowCoord[0] + dx0, shadowCoord[1] + dy1 ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( shadowCoord[0], shadowCoord[1] + dy1 ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( shadowCoord[0] + dx1, shadowCoord[1] + dy1 ), shadowCoord[2] )
			) * ( 1.0 / 17.0 );

		#elif defined( SHADOWMAP_TYPE_PCF_SOFT )

			var texelSize:Float32Array = vec2( 1.0 ) / shadowMapSize;
			var dx:Float = texelSize[0];
			var dy:Float = texelSize[1];

			var uv:Float32Array = vec2( shadowCoord[0], shadowCoord[1] );
			var f:Float32Array = fract( uv * shadowMapSize + 0.5 );
			uv -= f * texelSize;

			shadow = (
				texture2DCompare( shadowMap, uv, shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( uv[0] + dx, uv[1] ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( uv[0], uv[1] + dy ), shadowCoord[2] ) +
				texture2DCompare( shadowMap, vec2( uv[0] + dx, uv[1] + dy ), shadowCoord[2] ) +
				mix( texture2DCompare( shadowMap, vec2( uv[0] - dx, uv[1] ), shadowCoord[2] ),
					 texture2DCompare( shadowMap, vec2( uv[0] + 2.0 * dx, uv[1] ), shadowCoord[2] ),
					 f[0] ) +
				mix( texture2DCompare( shadowMap, vec2( uv[0] - dx, uv[1] + dy ), shadowCoord[2] ),
					 texture2DCompare( shadowMap, vec2( uv[0] + 2.0 * dx, uv[1] + dy ), shadowCoord[2] ),
					 f[0] ) +
				mix( texture2DCompare( shadowMap, vec2( uv[0], uv[1] - dy ), shadowCoord[2] ),
					 texture2DCompare( shadowMap, vec2( uv[0], uv[1] + 2.0 * dy ), shadowCoord[2] ),
					 f[1] ) +
				mix( texture2DCompare( shadowMap, vec2( uv[0] + dx, uv[1] - dy ), shadowCoord[2] ),
					 texture2DCompare( shadowMap, vec2( uv[0] + dx, uv[1] + 2.0 * dy ), shadowCoord[2] ),
					 f[1] ) +
				mix( mix( texture2DCompare( shadowMap, vec2( uv[0] - dx, uv[1] - dy ), shadowCoord[2] ),
						  texture2DCompare( shadowMap, vec2( uv[0] + 2.0 * dx, uv[1] - dy ), shadowCoord[2] ),
						  f[0] ),
					 mix( texture2DCompare( shadowMap, vec2( uv[0] - dx, uv[1] + 2.0 * dy ), shadowCoord[2] ),
						  texture2DCompare( shadowMap, vec2( uv[0] + 2.0 * dx, uv[1] + 2.0 * dy ), shadowCoord[2] ),
						  f[0] ),
					 f[1] )
			) * ( 1.0 / 9.0 );

		#elif defined( SHADOWMAP_TYPE_VSM )

			shadow = VSMShadow( shadowMap, vec2( shadowCoord[0], shadowCoord[1] ), shadowCoord[2] );

		#else // no percentage-closer filtering:

			shadow = texture2DCompare( shadowMap, vec2( shadowCoord[0], shadowCoord[1] ), shadowCoord[2] );

		#endif

		}

		return shadow;

	}

	function cubeToUV( v:Float32Array, texelSizeY:Float ):Float32Array {

		// Number of texels to avoid at the edge of each square

		var absV:Float32Array = abs( v );

		// Intersect unit cube

		var scaleToCube:Float = 1.0 / max( absV[0], max( absV[1], absV[2] ) );
		absV *= scaleToCube;

		// Apply scale to avoid seams

		// two texels less per square (one texel will do for NEAREST)
		v *= scaleToCube * ( 1.0 - 2.0 * texelSizeY );

		// Unwrap

		// space: -1 ... 1 range for each square
		//
		// #X##		dim    := ( 4 , 2 )
		//  # #		center := ( 1 , 1 )

		var planar:Float32Array = vec2( v[0], v[1] );

		var almostATexel:Float = 1.5 * texelSizeY;
		var almostOne:Float = 1.0 - almostATexel;

		if ( absV[2] >= almostOne ) {

			if ( v[2] > 0.0 )
				planar[0] = 4.0 - v[0];

		} else if ( absV[0] >= almostOne ) {

			var signX:Float = sign( v[0] );
			planar[0] = v[2] * signX + 2.0 * signX;

		} else if ( absV[1] >= almostOne ) {

			var signY:Float = sign( v[1] );
			planar[0] = v[0] + 2.0 * signY + 2.0;
			planar[1] = v[2] * signY - 2.0;

		}

		// Transform to UV space

		// scale := 0.5 / dim
		// translate := ( center + 0.5 ) / dim
		return vec2( 0.125, 0.25 ) * planar + vec2( 0.375, 0.75 );

	}

	function getPointShadow( shadowMap:DynamicTexture, shadowMapSize:Float32Array, shadowBias:Float, shadowRadius:Float, shadowCoord:Float32Array, shadowCameraNear:Float, shadowCameraFar:Float ):Float {

		var shadow:Float = 1.0;

		// for point lights, the uniform @vShadowCoord is re-purposed to hold
		// the vector from the light to the world-space position of the fragment.
		var lightToPosition:Float32Array = shadowCoord;

		var lightToPositionLength:Float = length( lightToPosition );

		if ( lightToPositionLength - shadowCameraFar <= 0.0 && lightToPositionLength - shadowCameraNear >= 0.0 ) {

			// dp = normalized distance from light to fragment position
			var dp:Float = ( lightToPositionLength - shadowCameraNear ) / ( shadowCameraFar - shadowCameraNear ); // need to clamp?
			dp += shadowBias;

			// bd3D = base direction 3D
			var bd3D:Float32Array = normalize( lightToPosition );

			var texelSize:Float32Array = vec2( 1.0 ) / ( shadowMapSize * vec2( 4.0, 2.0 ) );

			#if defined( SHADOWMAP_TYPE_PCF ) || defined( SHADOWMAP_TYPE_PCF_SOFT ) || defined( SHADOWMAP_TYPE_VSM )

				var offset:Float32Array = vec2( - 1, 1 ) * shadowRadius * texelSize[1];

				shadow = (
					texture2DCompare( shadowMap, cubeToUV( vec3( bd3D[0] + offset[0], bd3D[1] + offset[1], bd3D[2] ), texelSize[1] ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( vec3( bd3D[0] + offset[1], bd3D[1] + offset[1], bd3D[2] ), texelSize[1] ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( vec3( bd3D[0] + offset[0], bd3D[1], bd3D[2] ), texelSize[1] ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( vec3( bd3D[0] + offset[1], bd3D[1], bd3D[2] ), texelSize[1] ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( vec3( bd3D[0], bd3D[1], bd3D[2] ), texelSize[1] ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( vec3( bd3D[0] + offset[0], bd3D[1] + offset[0], bd3D[2] ), texelSize[1] ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( vec3( bd3D[0] + offset[1], bd3D[1] + offset[0], bd3D[2] ), texelSize[1] ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( vec3( bd3D[0] + offset[0], bd3D[1] + offset[0], bd3D[2] ), texelSize[1] ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( vec3( bd3D[0] + offset[1], bd3D[1] + offset[0], bd3D[2] ), texelSize[1] ), dp )
				) * ( 1.0 / 9.0 );

			#else // no percentage-closer filtering

				shadow = texture2DCompare( shadowMap, cubeToUV( vec3( bd3D[0], bd3D[1], bd3D[2] ), texelSize[1] ), dp );

			#endif

		}

		return shadow;

	}

#end