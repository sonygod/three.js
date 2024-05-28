class AlphaHash {
    public static function getFragmentCode():String {
        return "#ifdef USE_ALPHAHASH\n" +
            "if (diffuseColor.a < getAlphaHashThreshold(vPosition)) discard;\n" +
            "#endif";
    }
}