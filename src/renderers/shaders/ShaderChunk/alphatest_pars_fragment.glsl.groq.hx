package three.js.src.renderers.shaders.ShaderChunk;

class AlphatestParsFragment {
    public static var shaderSrc:String = "
#ifdef USE_ALPHATEST
    uniform float alphaTest;
#endif
    ";
}