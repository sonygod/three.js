package three.renderers.shaders.ShaderChunk;

class Metalnessmap_pars_fragment {
    static public function main() {
        #if (USE_METALNESSMAP)
            var metalnessMap:Sampler2D;
        #end
    }
}