package three.renderers.shaders.ShaderChunk;

class LogDepthBufParsFragment {
    public static var source = 
#if defined( USE_LOGDEPTHBUF )
        "
            uniform float logDepthBufFC;
            varying float vFragDepth;
            varying float vIsPerspective;
        "
#end;
}