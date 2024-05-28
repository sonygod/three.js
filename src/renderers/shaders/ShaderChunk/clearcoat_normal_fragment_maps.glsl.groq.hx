package three.shader;

class ClearcoatNormalFragmentMaps {
    public function new() {}

    #if USE_CLEARCOAT_NORMALMAP

    public function fragment() {
        var clearcoatMapN:Vec3 = texture2D(clearcoatNormalMap, vClearcoatNormalMapUv).xyz * 2.0 - 1.0;
        clearcoatMapN.xy *= clearcoatNormalScale;
        clearcoatNormal = normalize(tbn2 * clearcoatMapN);
    }

    #end
}