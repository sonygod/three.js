#if USE_CLEARCOAT_NORMALMAP

	var clearcoatMapN:Vec3 = texture2D(clearcoatNormalMap, vClearcoatNormalMapUv).xyz * 2.0 - 1.0;
	clearcoatMapN.xy *= clearcoatNormalScale;

	clearcoatNormal = normalize(tbn2 * clearcoatMapN);

#end