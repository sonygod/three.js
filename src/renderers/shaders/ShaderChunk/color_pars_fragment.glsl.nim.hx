package three.renderers.shaders.ShaderChunk;

class color_pars_fragment {
    static function main() {
        #if (USE_COLOR_ALPHA) {
            var vColor = Varying(Vec4, "vColor");
        #elseif (USE_COLOR) {
            var vColor = Varying(Vec3, "vColor");
        #end
    }
}