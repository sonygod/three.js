function clearCoatNormalMap_fragment() {
	#if USE_CLEARCOAT_NORMALMAP

	var clearcoatMapN = clearcoatNormalMap.sample(clearcoatNormalMap_sampler, vClearcoatNormalMapUv).xyz * 2.0 - 1.0;
	clearcoatMapN.xy *= clearcoatNormalScale;

	clearcoatNormal = normalize( tbn2 * clearcoatMapN );

	#end
}