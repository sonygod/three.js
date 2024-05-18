package renderers.shaders.ShaderChunk;

class BeginNormal_Vertex {
    static inline function shader():String {
        return "
            vec3 objectNormal = vec3( normal );

            #ifdef USE_TANGENT

            vec3 objectTangent = vec3( tangent.xyz );

            #endif
        ";
    }
}