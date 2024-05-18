package three.shader;

class TonemappingFragment {
    public static var shader:String = "
#if defined( TONE_MAPPING )

	gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );

#endif
";
}