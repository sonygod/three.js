class DisplacementMapParsVertex {
    static public function getShaderChunk():String {
        return """
        #ifdef USE_DISPLACEMENTMAP

            uniform sampler2D displacementMap;
            uniform float displacementScale;
            uniform float displacementBias;

        #endif
        """;
    }
}