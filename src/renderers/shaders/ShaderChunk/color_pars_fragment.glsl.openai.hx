package three.renderers.shaders.ShaderChunk;

class ColorParsFragment {
    public static var shader:String = "
#if defined( USE_COLOR_ALPHA )

	varying vec4 vColor;

#elif defined( USE_COLOR )

	varying vec3 vColor;

#endif
";
}