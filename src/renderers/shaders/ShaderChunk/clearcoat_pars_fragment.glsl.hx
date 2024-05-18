package renderers.shaders.ShaderChunk;

class ClearcoatParsFragment {
    #if USE_CLEARCOATMAP
    @:uniform var clearcoatMap:Sampler2D;
    #end

    #if USE_CLEARCOAT_NORMALMAP
    @:uniform var clearcoatNormalMap:Sampler2D;
    @:uniform var clearcoatNormalScale:Vec2;
    #end

    #if USE_CLEARCOAT_ROUGHNESSMAP
    @:uniform var clearcoatRoughnessMap:Sampler2D;
    #end
}