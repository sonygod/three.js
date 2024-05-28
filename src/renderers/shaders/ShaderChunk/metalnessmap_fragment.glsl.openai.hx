package three.shader.lib;

class MetalnessMapFragment {
  public static var shader:String = "
    float metalnessFactor = metalness;

    #ifdef USE_METALNESSMAP

      vec4 texelMetalness = texture2D(metalnessMap, vMetalnessMapUv);

      // reads channel B, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
      metalnessFactor *= texelMetalness.b;

    #endif
  ";
}