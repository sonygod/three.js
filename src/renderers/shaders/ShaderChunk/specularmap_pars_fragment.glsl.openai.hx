package three.js.src.renderers.shaders.ShaderChunk;

class SpecularmapParsFragment {
    public static var glsl:String = '
#ifdef USE_SPECULARMAP

    uniform sampler2D specularMap;

#endif
';
}