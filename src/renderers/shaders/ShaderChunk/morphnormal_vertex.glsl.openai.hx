package three.shaderlib.ShaderChunk;

class MorphNormalVertex {

    @glFragmentData("
        #ifdef USE_MORPHNORMALS

        objectNormal *= morphTargetBaseInfluence;

        for (i in 0...MORPHTARGETS_COUNT) {
            if (morphTargetInfluences[i] != 0.0) {
                objectNormal += getMorph(gl_VertexID, i, 1).xyz * morphTargetInfluences[i];
            }
        }

        #endif
    ")
    public function new() {}
}