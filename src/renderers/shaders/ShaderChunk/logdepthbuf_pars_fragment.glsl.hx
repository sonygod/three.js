package three.renderers.shaders.ShaderChunk;

class LogDepthBufParsFragment {
    @:glsl("
#if defined( USE_LOGDEPTHBUF )

    uniform float logDepthBufFC;
    varying float vFragDepth;
    varying float vIsPerspective;

#endif
");
}