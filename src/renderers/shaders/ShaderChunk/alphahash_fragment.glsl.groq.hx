package three.shaderlib;

@:keep
class AlphaHashFragment {
    public static function main() {
        #ifdef USE_ALPHAHASH
        if (diffuseColor.a < getAlphaHashThreshold(vPosition)) {
            discard;
        }
        #end
    }
}