package three.shader;

@:header("uniform sampler2D emissiveMap;")

class EmissiveMapParsFragment {
    #ifdef USE_EMISSIVEMAP
    public function new() {
    }
    #end
}