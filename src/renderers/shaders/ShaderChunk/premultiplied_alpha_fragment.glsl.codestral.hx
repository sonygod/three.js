class PremultipliedAlphaFragment {
    public static function getFragment():String {
        return "#ifdef PREMULTIPLIED_ALPHA\n" +
               "    // Get get normal blending with premultipled, use with CustomBlending, OneFactor, OneMinusSrcAlphaFactor, AddEquation.\n" +
               "    gl_FragColor.rgb *= gl_FragColor.a;\n" +
               "#endif\n";
    }
}