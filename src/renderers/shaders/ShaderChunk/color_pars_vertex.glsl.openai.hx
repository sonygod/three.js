package three.js.src.renderers.shaders.ShaderChunk;

class ColorParsVertex {
    public static var glsl(get, never):String;

    private static function get_glsl():String {
        return [
            '#if defined( USE_COLOR_ALPHA )',
            '    varying vec4 vColor;',
            '#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR ) || defined( USE_BATCHING_COLOR )',
            '    varying vec3 vColor;',
            '#endif'
        ].join('\n');
    }
}