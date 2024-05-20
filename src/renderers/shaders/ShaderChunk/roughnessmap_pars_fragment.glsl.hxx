@:js(`
#ifdef USE_ROUGHNESSMAP

	uniform sampler2D roughnessMap;

#endif
`)
class ShaderChunk {
    public static var roughnessmap_pars_fragment:String;
}