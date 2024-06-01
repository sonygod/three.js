class MyShader {
  public static function main(): String {
    return /* glsl */
      "float metalnessFactor = metalness;\n" +
      "#ifdef USE_METALNESSMAP\n" +
      "  vec4 texelMetalness = texture2D(metalnessMap, vMetalnessMapUv);\n" +
      "  // reads channel B, compatible with a combined OcclusionRoughnessMetallic (RGB) texture\n" +
      "  metalnessFactor *= texelMetalness.b;\n" +
      "#endif\n";
  }
}