class PremultipliedAlphaFragment {
    public static inline var source: String = "
        #ifdef PREMULTIPLIED_ALPHA

            // Get normal blending with premultipled, use with CustomBlending, OneFactor, OneMinusSrcAlphaFactor, AddEquation.
            gl_FragColor.rgb *= gl_FragColor.a;

        #endif
    ";
}