class MetalnessMapParsFragment {
    public static var code:String;

    static function init() {
        code = """
        #ifdef USE_METALNESSMAP

            uniform sampler2D metalnessMap;

        #endif
        """;
    }
}