class NormalParsFragment {
    public static function getShaderCode():String {
        return """
#ifndef FLAT_SHADED

    varying vec3 vNormal;

    #ifdef USE_TANGENT

        varying vec3 vTangent;
        varying vec3 vBitangent;

    #endif

#endif
""";
    }
}