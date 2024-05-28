return """
#if NUM_CLIPPING_PLANES > 0

	var plane:Vec4;

	#if ALPHA_TO_COVERAGE

		var distanceToPlane:Float, distanceGradient:Float;
		var clipOpacity:Float = 1.0;

		#pragma unroll_loop_start
		for ( i in 0...UNION_CLIPPING_PLANES ) {

			plane = clippingPlanes[i];
			distanceToPlane = -dot( vClipPosition, plane.xyz ) + plane.w;
			distanceGradient = fwidth( distanceToPlane ) / 2.0;
			clipOpacity *= smoothstep( -distanceGradient, distanceGradient, distanceToPlane );

			if ( clipOpacity == 0.0 ) {
				discard;
			}

		}
		#pragma unroll_loop_end

		#if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES

			var unionClipOpacity:Float = 1.0;

			#pragma unroll_loop_start
			for ( i in UNION_CLIPPING_PLANES...NUM_CLIPPING_PLANES ) {

				plane = clippingPlanes[i];
				distanceToPlane = -dot( vClipPosition, plane.xyz ) + plane.w;
				distanceGradient = fwidth( distanceToPlane ) / 2.0;
				unionClipOpacity *= 1.0 - smoothstep( -distanceGradient, distanceGradient, distanceToPlane );

			}
			#pragma unroll_loop_end

			clipOpacity *= 1.0 - unionClipOpacity;

		#endif

		diffuseColor.a *= clipOpacity;

		if ( diffuseColor.a == 0.0 ) {
			discard;
		}

	#else

		#pragma unroll_loop_start
		for ( i in 0...UNION_CLIPPING_PLANES ) {

			plane = clippingPlanes[i];
			if ( dot( vClipPosition, plane.xyz ) > plane.w ) {
				discard;
			}

		}
		#pragma unroll_loop_end

		#if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES

			var clipped:Bool = true;

			#pragma unroll_loop_start
			for ( i in UNION_CLIPPING_PLANES...NUM_CLIPPING_PLANES ) {

				plane = clippingPlanes[i];
				clipped = ( dot( vClipPosition, plane.xyz ) > plane.w ) && clipped;

			}
			#pragma unroll_loop_end

			if ( clipped ) {
				discard;
			}

		#endif

	#endif

#endif
""";