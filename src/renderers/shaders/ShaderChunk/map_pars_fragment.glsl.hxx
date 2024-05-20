class ShaderChunk {
    public static var map_pars_fragment:String =
        #if USE_MAP
            uniform sampler2D map;
        #end
        "";
}