package three.shader;

class MorphColorVertex {

    @glsl("ShaderChunk")
    public static var shader: String = "

#if defined( USE_MORPHCOLORS )

    vColor *= morphTargetBaseInfluence;

    for (i in 0...MORPHTARGETS_COUNT) {

        #if defined( USE_COLOR_ALPHA )

            if (morphTargetInfluences[i] != 0.0) vColor += getMorph(gl_VertexID, i, 2) * morphTargetInfluences[i];

        #elseif defined( USE_COLOR )

            if (morphTargetInfluences[i] != 0.0) vColor += getMorph(gl_VertexID, i, 2).rgb * morphTargetInfluences[i];

        #end

    }

#endif

";

}