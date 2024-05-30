package three.src.renderers.shaders.ShaderChunk;

class MapParsFragment {
    public static inline function main() {
        #if USE_MAP
            var map: sampler2D;
        #end
    }
}