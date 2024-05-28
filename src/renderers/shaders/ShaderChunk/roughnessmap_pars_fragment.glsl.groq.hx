@:glsl("roughnessmap_pars_fragment")
class RoughnessMapParsFragment {
    #if USE_ROUGHNESSMAP
    public var roughnessMap:Sampler2D;
    #end
}