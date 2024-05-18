package three.renderers.shaders;

@:glsl("ShaderChunk.specularmap_pars_fragment.glsl")
class SpecularMapParsFragmentGlsl {
    @ifdef("USE_SPECULARMAP")
    public var specularMap:Sampler2D;
}