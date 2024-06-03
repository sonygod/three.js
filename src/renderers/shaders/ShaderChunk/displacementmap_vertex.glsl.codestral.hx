class Displacementmap_vertex {
    static function getShaderChunk(): String {
        return """
        #ifdef USE_DISPLACEMENTMAP

            transformed += normalize( objectNormal ) * ( texture2D( displacementMap, vDisplacementMapUv ).x * displacementScale + displacementBias );

        #endif
        """;
    }
}