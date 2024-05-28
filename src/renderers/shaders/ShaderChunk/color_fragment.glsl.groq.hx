package three.renderers.shaders.ShaderChunk;

class ColorFragmentGlsl {
    public static var src:String = "
#if defined( USE_COLOR_ALPHA )

	diffuseColor *= vColor;

#elif defined( USE_COLOR )

	diffuseColor.rgb *= vColor;

#endif
";
}