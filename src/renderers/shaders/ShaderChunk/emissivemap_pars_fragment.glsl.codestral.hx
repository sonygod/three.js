class EmissiveMapParsFragment {
    public static function getCode():String {
        return """
        #ifdef USE_EMISSIVEMAP

            uniform sampler2D emissiveMap;

        #endif
        """;
    }
}