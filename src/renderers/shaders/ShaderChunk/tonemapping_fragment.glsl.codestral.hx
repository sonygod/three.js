class TonemappingFragment {
    public static var code:String = """
#if defined( TONE_MAPPING)

	gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );

#endif
""";
}