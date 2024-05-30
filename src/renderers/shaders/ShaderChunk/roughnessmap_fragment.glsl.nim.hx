package three.renderers.shaders.ShaderChunk;

@:build(macro.ShaderChunkMacro.build("roughnessmap_fragment.glsl"))
class RoughnessmapFragment {

    public static inline var roughnessFactor(roughness:Float, roughnessMap:Null<Dynamic>, vRoughnessMapUv:Dynamic):Float {
        var roughnessFactor = roughness;

        #if use_roughnessmap

            var texelRoughness = roughnessMap.texture2D(vRoughnessMapUv);

            // reads channel G, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
            roughnessFactor *= texelRoughness.g;

        #end

        return roughnessFactor;
    }
}