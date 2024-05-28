package three.renderers.shaders.ShaderChunk;

class SpecularmapParsFragment {
    public static var shader:String = '

#ifdef USE_SPECULARMAP

	uniform sampler2D specularMap;

#endif

';
}