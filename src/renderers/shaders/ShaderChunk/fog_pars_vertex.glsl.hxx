class ShaderChunk {
    public static var fog_pars_vertex:String =
        #if USE_FOG
            varying float vFogDepth;
        #end;
}