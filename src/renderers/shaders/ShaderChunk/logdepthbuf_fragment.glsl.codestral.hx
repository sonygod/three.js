class LogDepthBufFragment {
    public static function getShaderCode():String {
        return "#if defined( USE_LOGDEPTHBUF )\n" +
               "    gl_FragDepth = vIsPerspective == 0.0 ? gl_FragCoord.z : log2( vFragDepth ) * logDepthBufFC * 0.5;\n" +
               "#endif\n";
    }
}