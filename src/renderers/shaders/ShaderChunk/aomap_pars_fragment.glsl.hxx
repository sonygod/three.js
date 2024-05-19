class ShaderChunk {
    public static var aomap_pars_fragment:String =
        #if USE_AOMAP
            "uniform sampler2D aoMap;" +
            "uniform float aoMapIntensity;" +
        #end;
}