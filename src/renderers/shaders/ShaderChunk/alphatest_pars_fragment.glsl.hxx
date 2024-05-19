import haxe.Resource;

class Main {
    static function main() {
        var shaderChunk = Resource.fromString(
            #if USE_ALPHATEST
                uniform float alphaTest;
            #end
        , "glsl");

        // 使用shaderChunk
    }
}