package renderers.shaders.ShaderChunk;

class MorphNormalVertex {
    public function new() {}

    public static function shader():String {
        var shader = "";

        #if USE_MORPHNORMALS
        shader += "
            objectNormal *= morphTargetBaseInfluence;

            for (i in 0...MORPHTARGETS_COUNT) {
                if (morphTargetInfluences[i] != 0.0) objectNormal += getMorph(gl_VertexID, i, 1).xyz * morphTargetInfluences[i];
            }
        ";
        #end

        return shader;
    }
}