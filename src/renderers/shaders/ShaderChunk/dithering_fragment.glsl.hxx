class DitheringFragment {
    public static var shaderChunk:String =
        #if DITHERING
            gl_FragColor.rgb = dithering( gl_FragColor.rgb );
        #end
    ;
}