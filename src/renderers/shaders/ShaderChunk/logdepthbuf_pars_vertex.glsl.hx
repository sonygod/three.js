package three.renderers.shaders.ShaderChunk;

class LogDepthBufParsVertex {
    @glsl("vert")
    public static var shader:String = "
#ifdef USE_LOGDEPTHBUF

    varying float vFragDepth;
    varying float vIsPerspective;

#endif
    ";
}