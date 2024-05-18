package three.shaderlib;

class ClearcoatNormalFragmentBegin {
    public static inline function getFragment():String {
        return "
#ifdef USE_CLEARCOAT

	vec3 clearcoatNormal = nonPerturbedNormal;

#endif
";
    }
}