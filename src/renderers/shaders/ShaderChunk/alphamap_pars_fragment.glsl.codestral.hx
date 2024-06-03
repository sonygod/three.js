class AlphamapParsFragment {
    public static function getShaderCode():String {
        return """
        #ifdef USE_ALPHAMAP
            uniform sampler2D alphaMap;
        #endif
        """;
    }
}