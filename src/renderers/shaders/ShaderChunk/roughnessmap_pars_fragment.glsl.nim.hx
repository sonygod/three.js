package three.src.renderers.shaders.ShaderChunk;

class Roughnessmap_pars_fragment {
    #if USE_ROUGHNESSMAP
        public static var roughnessMap:sampler2D;
    #end
}