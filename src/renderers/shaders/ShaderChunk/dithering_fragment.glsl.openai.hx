package three.js.src.renderers.shaders.ShaderChunk;

class DitheringFragmentGlsl {
  public static var shader:String = "

#ifdef DITHERING

	gl_FragColor.rgb = dithering( gl_FragColor.rgb );

#endif

";
}