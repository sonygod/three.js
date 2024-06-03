import js.Browser.document;

class LightmapParsFragment {
    public static function getCode():String {
        return """
#ifdef USE_LIGHTMAP

	uniform sampler2D lightMap;
	uniform float lightMapIntensity;

#endif
""";
    }
}