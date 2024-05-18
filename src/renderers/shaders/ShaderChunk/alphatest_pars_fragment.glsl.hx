package renderers.shaders.ShaderChunk;

class AlphaTestParsFragment {
    static var shaderSrc:String = "
#ifdef USE_ALPHATEST
	uniform float alphaTest;
#endif
";
}