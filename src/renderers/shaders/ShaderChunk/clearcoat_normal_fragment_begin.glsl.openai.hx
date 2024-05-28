package three.renderers.shaders.ShaderChunk;

class ClearcoatNormalFragmentBegin {
    public static inline function getFragment() {
        #ifdef USE_CLEARCOAT
        var clearcoatNormal:Vec3 = nonPerturbedNormal;
        #end
    }
}