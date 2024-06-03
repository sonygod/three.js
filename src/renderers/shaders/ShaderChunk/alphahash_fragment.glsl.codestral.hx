class AlphaHashFragment {
    public static function getFragmentShader():String {
        return """
#ifdef USE_ALPHASH

	if (diffuseColor.a < getAlphaHashThreshold(vPosition)) discard;

#endif
""";
    }
}