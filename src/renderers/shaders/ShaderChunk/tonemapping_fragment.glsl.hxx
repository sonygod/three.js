import js.Lib;

class Main {
    static function main() {
        var glslCode = haxe.Resource.fromString(`
            #if defined( TONE_MAPPING )

                gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );

            #endif
        `);

        // 使用glslCode
    }
}