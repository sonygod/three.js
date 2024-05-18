package renderers.shaders.ShaderChunk;

class RoughnessMapParsFragmentGlsl {
    public static var shader:String = "
#ifdef USE_ROUGHNESSMAP

    uniform sampler2D roughnessMap;

#endif
";
}