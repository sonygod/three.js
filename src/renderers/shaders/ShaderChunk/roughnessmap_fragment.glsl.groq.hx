package three.js.src.renderers.shaders.ShaderChunk;

class RoughnessMapFragmentGlsl {
    public static var shaderCode:String = "
        float roughnessFactor = roughness;

        #ifdef USE_ROUGHNESSMAP

            vec4 texelRoughness = texture2D( roughnessMap, vRoughnessMapUv );

            // reads channel G, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
            roughnessFactor *= texelRoughness.g;

        #endif
    ";
}