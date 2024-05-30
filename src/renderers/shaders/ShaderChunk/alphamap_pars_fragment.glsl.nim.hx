package three.renderers.shaders.ShaderChunk;

class Alphamap_pars_fragment {
    static public var code(inline:Bools) {
        #if use_alphamap
            var code = "uniform sampler2D alphaMap;";
        #end
        return code;
    }
}