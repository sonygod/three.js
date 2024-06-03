class RoughnessmapFragmentShader {
    static function getShaderChunk(): String {
        return '
float roughnessFactor = roughness;

#ifdef USE_ROUGHNESSMAP
    vec4 texelRoughness = texture2D( roughnessMap, vRoughnessMapUv );
    roughnessFactor *= texelRoughness.g;
#endif
        ';
    }
}