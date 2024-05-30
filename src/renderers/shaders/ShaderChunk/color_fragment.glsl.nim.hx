package three.renderers.shaders.ShaderChunk;

class color_fragment {
    static public function main() {
        #if (USE_COLOR_ALPHA) {
            diffuseColor *= vColor;
        } else if (USE_COLOR) {
            diffuseColor.rgb *= vColor;
        }
        return null;
    }
}