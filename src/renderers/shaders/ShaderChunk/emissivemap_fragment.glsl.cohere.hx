function glsl() return
#if USE_EMISSIVEMAP

	var emissiveColor = texture2D(emissiveMap, vEmissiveMapUv);

	totalEmissiveRadiance *= emissiveColor.rgb;

#end;