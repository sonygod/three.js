package three.src.renderers.shaders.ShaderChunk;

class Emissivemap_pars_fragment {
    public static inline function get() {
        #if (USE_EMISSIVEMAP)
            return "uniform sampler2D emissiveMap;";
        #else
            return "";
        #end
    }
}