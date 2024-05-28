package three.renderers.shaders.ShaderChunk;

class MorphtargetVertexGlsl {
    public function new() {}

    public static function getShaderCode():String {
        return '
#ifdef USE_MORPHTARGETS

    transformed *= morphTargetBaseInfluence;

    for (i in 0...MORPHTARGETS_COUNT) {
        if (morphTargetInfluences[i] != 0.0) {
            transformed += getMorph(gl_VertexID, i, 0).xyz * morphTargetInfluences[i];
        }
    }

#endif
';
    }
}