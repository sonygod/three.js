class AlphaMapFragment {
    public static var code:String = """
        #ifdef USE_ALPHAMAP

            diffuseColor.a *= texture2D( alphaMap, vAlphaMapUv ).g;

        #endif
    """;
}