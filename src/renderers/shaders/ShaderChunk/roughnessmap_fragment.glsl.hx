package three.shader;

class RoughnessMapFragment {
    public static var shader:String = '
        #ifdef USE_ROUGHNESSMAP

        uniform sampler2D roughnessMap;
        varying vec2 vRoughnessMapUv;

        void main(void) {
            float roughnessFactor = roughness;

            vec4 texelRoughness = texture2D(roughnessMap, vRoughnessMapUv);

            // reads channel G, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
            roughnessFactor *= texelRoughness.g;
        }

        #endif
    ';
}