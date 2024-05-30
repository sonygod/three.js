package three.renderers.shaders.ShaderChunk;

class ColorParsVertex {
    public static inline var shader: String = '
        #if defined( USE_COLOR_ALPHA )
            varying vec4 vColor;
        #elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR ) || defined( USE_BATCHING_COLOR )
            varying vec3 vColor;
        #endif
    ';
}