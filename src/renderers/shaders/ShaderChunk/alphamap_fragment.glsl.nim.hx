package three.src.renderers.shaders.ShaderChunk;

class AlphamapFragment {
    public static inline function main() {
        #if use_alphamap
            diffuseColor.a *= cast(Float, texture2D(alphaMap, vAlphaMapUv).g);
        #end
        return "";
    }
}