package three.renderers.shaders.ShaderChunk;

#if !macro
@:glsl("alphamap_pars_fragment.glsl")
#end

class AlphaMapParsFragment {
    #if USE_ALPHAMAP
    @:uniform var alphaMap:Sampler2D;
    #end
}