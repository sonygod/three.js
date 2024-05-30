package three.src.renderers.shaders.ShaderChunk;

class Displacementmap_pars_vertex {
    public static inline function main() {
        #if (USE_DISPLACEMENTMAP)
            var displacementMap: sampler2D;
            var displacementScale: Float;
            var displacementBias: Float;
        #end
    }
}