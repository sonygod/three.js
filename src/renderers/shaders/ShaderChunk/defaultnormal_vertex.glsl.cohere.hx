return """
	vec3 transformedNormal = objectNormal;
	#if defined( USE_TANGENT )
		vec3 transformedTangent = objectTangent;
	#endif
	#if defined( USE_BATCHING )
		// this is in lieu of a per-instance normal-matrix
		// shear transforms in the instance matrix are not supported
		mat3 bm = mat3( batchingMatrix );
		transformedNormal /= vec3( dot( bm[ 0 ], bm[ 0 ] ), dot( bm[ 1 ], bm[ 1 ] ), dot( bm[ 2 ], bm[ 2 ] ) );
		transformedNormal = bm * transformedNormal;
		#if defined( USE_TANGENT )
			transformedTangent = bm * transformedTangent;
		#endif
	#endif
	#if defined( USE_INSTANCING )
		// this is in lieu of a per-instance normal-matrix
		// shear transforms in the instance matrix are not supported
		mat3 im = mat3( instanceMatrix );
		transformedNormal /= vec3( dot( im[ 0 ], im[ 0 ] ), dot( im[ 1 ], im[ 1 ] ), dot( im[ 2 ], im[ 2 ] ) );
		transformedNormal = im * transformedNormal;
		#if defined( USE_TANGENT )
			transformedTangent = im * transformedTangent;
		#endif
	#endif
	transformedNormal = normalMatrix * transformedNormal;
	#if defined( FLIP_SIDED )
		transformedNormal = - transformedNormal;
	#endif
	#if defined( USE_TANGENT )
		transformedTangent = ( modelViewMatrix * vec4( transformedTangent, 0.0 ) ).xyz;
		#if defined( FLIP_SIDED )
			transformedTangent = - transformedTangent;
		#endif
	#endif
""";