class ShaderChunk_fog_vertex {
    static function getCode():String {
        return """
        #ifdef USE_FOG
            vFogDepth = - mvPosition.z;
        #endif
        """;
    }
}