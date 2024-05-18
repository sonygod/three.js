package three.renderers.shaders.ShaderChunk;

class ColorFragmentGlsl {
    public static var shader:String = '
#if defined( USE_COLOR_ALPHA )

	diffuseColor *= vColor;

#elif defined( USE_COLOR )

	diffuseColor.rgb *= vColor;

#endif
';
}