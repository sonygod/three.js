#ifndef FLAT_SHADED // normal is computed with derivatives when FLAT_SHADED

	var vNormal = normalize( transformedNormal );

	#ifdef USE_TANGENT

		var vTangent = normalize( transformedTangent );
		var vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );

	#endif

#endif