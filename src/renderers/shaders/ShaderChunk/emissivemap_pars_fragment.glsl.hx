package three.shaderlib.ShaderChunk;

class EmissiveMapParsFragment {
    @:glsl("
#ifdef USE_EMISSIVEMAP

uniform sampler2D emissiveMap;

#endif
")
    public function new() {}
}