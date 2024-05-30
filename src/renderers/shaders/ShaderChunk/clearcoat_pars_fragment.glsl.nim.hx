package three.renderers.shaders.ShaderChunk;

class clearcoat_pars_fragment {
    static function main() {
        #if (USE_CLEARCOATMAP)
            var clearcoatMap:Sampler2D;
        #end

        #if (USE_CLEARCOAT_NORMALMAP)
            var clearcoatNormalMap:Sampler2D;
            var clearcoatNormalScale:Vec2;
        #end

        #if (USE_CLEARCOAT_ROUGHNESSMAP)
            var clearcoatRoughnessMap:Sampler2D;
        #end
    }
}