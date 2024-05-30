package three.renderers.shaders.ShaderChunk;

class NormalVertex {
    public static inline function normal_vertex_glsl():String {
        #if !FLAT_SHADED // normal is computed with derivatives when FLAT_SHADED
            return "vNormal = normalize( transformedNormal );\n" +
                #if USE_TANGENT
                    "vTangent = normalize( transformedTangent );\n" +
                    "vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );\n" +
                #end
            ;
        #end
        return "";
    }
}