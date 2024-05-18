package three.shader;

class EmissiveMapFragment {
    @glsl("
#ifdef USE_EMISSIVEMAP

	vec4 emissiveColor = texture2D( emissiveMap, vEmissiveMapUv );

	totalEmissiveRadiance *= emissiveColor.rgb;

#endif
")
    public function new() {}
}