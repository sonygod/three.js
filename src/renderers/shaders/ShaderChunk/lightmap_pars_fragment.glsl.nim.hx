package three.src.renderers.shaders.ShaderChunk;

class LightmapParsFragment {
    static var code: String;

    static function main() {
        code = "#ifdef USE_LIGHTMAP\n" +
               "\n" +
               "	uniform sampler2D lightMap;\n" +
               "	uniform float lightMapIntensity;\n" +
               "\n" +
               "#endif";
    }
}