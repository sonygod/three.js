class EnvmapCommonParsFragment {
    public static function getCode():String {
        return """
        #ifdef USE_ENVMAP

            uniform float envMapIntensity;
            uniform float flipEnvMap;
            uniform mat3 envMapRotation;

            #ifdef ENVMAP_TYPE_CUBE
                uniform samplerCube envMap;
            #else
                uniform sampler2D envMap;
            #endif

        #endif
        """;
    }
}