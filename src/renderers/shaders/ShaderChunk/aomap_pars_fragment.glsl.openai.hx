package three.renderers.shaders.ShaderChunk;

class AOMAP_PARS_FRAGMENT {
    @glsl("ifdef USE_AOMAP")
    public var aoMap:Sampler2D;
    @glsl("ifdef USE_AOMAP")
    public var aoMapIntensity:Float;
}