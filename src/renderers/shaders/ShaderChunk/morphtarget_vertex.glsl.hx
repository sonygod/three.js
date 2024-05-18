package renderers.shaders.ShaderChunk;

import haxe.macro.Expr;

class MorphtargetVertexGlsl {
    public static var shaderCode:String = "
#ifdef USE_MORPHTARGETS

    transformed *= morphTargetBaseInfluence;

    for (i in 0...MORPHTARGETS_COUNT) {
        if (morphTargetInfluences[i] != 0.0) transformed += getMorph(gl_VertexID, i, 0).xyz * morphTargetInfluences[i];
    }

#endif
";
}