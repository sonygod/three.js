package three.js.src.renderers.shaders.ShaderChunk;

class ClearcoatParsFragment {
    #ifdef USE_CLEARCOATMAP
    public var clearcoatMap:Sampler2D;
    #end

    #ifdef USE_CLEARCOAT_NORMALMAP
    public var clearcoatNormalMap:Sampler2D;
    public var clearcoatNormalScale:Vec2;
    #end

    #ifdef USE_CLEARCOAT_ROUGHNESSMAP
    public var clearcoatRoughnessMap:Sampler2D;
    #end
}