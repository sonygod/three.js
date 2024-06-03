class DitheringFragment {
    public static function getShaderCode():String {
        return "#ifdef DITHERING\n" +
               "\tgl_FragColor.rgb = dithering( gl_FragColor.rgb );\n" +
               "#endif\n";
    }
}