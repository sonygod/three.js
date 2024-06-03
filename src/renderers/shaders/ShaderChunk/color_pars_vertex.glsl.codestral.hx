// File path: three.js/src/renderers/shaders/ShaderChunk/color_pars_vertex.hx
class ColorParsVertex {
    static function toString():String {
        return """
        #if defined( USE_COLOR_ALPHA )

            varying vec4 vColor;

        #elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR ) || defined( USE_BATCHING_COLOR )

            varying vec3 vColor;

        #endif
        """;
    }
}