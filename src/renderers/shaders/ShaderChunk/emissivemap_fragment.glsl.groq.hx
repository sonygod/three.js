package three.shader.chunks;

class EmissiveMapFragment {
    public static var SRC: String = "
#ifdef USE_EMISSIVEMAP

	vec4 emissiveColor = texture2D( emissiveMap, vEmissiveMapUv );

	totalEmissiveRadiance *= emissiveColor.rgb;

#endif
";
}