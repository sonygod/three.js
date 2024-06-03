class MetalnessMapFragment {
    public static function getShaderChunk(): String {
        return """
        var metalnessFactor: Float = metalness;

        #if USE_METALNESSMAP

            var texelMetalness: Float4 = texture2D(metalnessMap, vMetalnessMapUv);

            // reads channel B, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
            metalnessFactor *= texelMetalness.b;

        #end
        """;
    }
}