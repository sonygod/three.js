package three.src.renderers.shaders.ShaderChunk;

class ColorParsVertex {
    public static inline function get() {
        #if defined(USE_COLOR_ALPHA)
            return "varying vec4 vColor;";
        #elseif defined(USE_COLOR) || defined(USE_INSTANCING_COLOR) || defined(USE_BATCHING_COLOR)
            return "varying vec3 vColor;";
        #end
    }
}