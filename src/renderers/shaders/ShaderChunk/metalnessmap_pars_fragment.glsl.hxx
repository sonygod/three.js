class MetalnessmapParsFragment {
    public static var shaderChunk:String =
        #if USE_METALNESSMAP
            uniform sampler2D metalnessMap;
        #end
        "";
}