class ColorFragmentShader {
    public static var code:String =
        #if defined( USE_COLOR_ALPHA )

            diffuseColor *= vColor;

        #elif defined( USE_COLOR )

            diffuseColor.rgb *= vColor;

        #endif
    ;
}