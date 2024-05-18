package three.shader;

class AlphaHashFragment {
    public function new() {}

    public static function fragment() {
        #if USE_ALPHAHASH
        if (diffuseColor.a < getAlphaHashThreshold(vPosition)) {
            discard;
        }
        #end
    }
}