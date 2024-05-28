class ClearCoatNormal {
    public static var code:String = #ifdef USE_CLEARCOAT
		${'\n'}    vec3 clearcoatNormal = nonPerturbedNormal;
		#endif;
}