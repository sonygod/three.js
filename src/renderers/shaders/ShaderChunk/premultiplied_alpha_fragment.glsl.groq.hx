package three.renderers.shaders.ShaderChunk;

class PremultipliedAlphaFragment {
    public static var SOURCE = "
#ifdef PREMULTIPLIED_ALPHA

	gl_FragColor.rgb *= gl_FragColor.a;

#endif
";
}