package three.src.renderers.shaders.ShaderChunk;

@:build(macro.ShaderChunkMacro.build("metalnessmap_fragment.glsl"))
class MetalnessmapFragment {

  static var metalnessFactor:Float = metalness;

  static var useMetalnessMap:Bool = false;
  #if useMetalnessMap

    static var texelMetalness:Float = cast(texture2D(metalnessMap, vMetalnessMapUv), Float).b;

    // reads channel B, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
    static var metalnessFactor:Float = metalnessFactor * texelMetalness;

  #end

}