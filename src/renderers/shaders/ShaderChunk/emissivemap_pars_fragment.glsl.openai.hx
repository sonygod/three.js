package three.shaderlib;

class EmissiveMap_pars_fragment {
    public static var Shader:String = "
#ifdef USE_EMISSIVEMAP

	uniform sampler2D emissiveMap;

#endif
";
}