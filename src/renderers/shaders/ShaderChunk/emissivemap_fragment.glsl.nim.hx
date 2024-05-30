package three.src.renderers.shaders.ShaderChunk;

class EmissivemapFragment {
    public static function main() {
        #if (USE_EMISSIVEMAP)
            var emissiveColor = texture2D(emissiveMap, vEmissiveMapUv);
            totalEmissiveRadiance *= emissiveColor.rgb;
        #end
        return null;
    }
}