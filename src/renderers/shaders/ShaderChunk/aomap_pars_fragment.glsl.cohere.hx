package openfl._internal.renderer.opengl;

class GLSL {
    public static var aoMap:String = """
#ifdef USE_AOMAP

	uniform sampler2D aoMap;
	uniform float aoMapIntensity;

#endif
""";
}