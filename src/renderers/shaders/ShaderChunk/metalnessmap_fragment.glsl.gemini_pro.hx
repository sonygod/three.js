class Glsl {
  public static function metalness(metalness:Float, metalnessMap:String, vMetalnessMapUv:String):String {
    return 
      "float metalnessFactor = ${metalness};\n" +
      "\n" +
      "#ifdef USE_METALNESSMAP\n" +
      "\n" +
      "  vec4 texelMetalness = texture2D(${metalnessMap}, ${vMetalnessMapUv});\n" +
      "\n" +
      "  // reads channel B, compatible with a combined OcclusionRoughnessMetallic (RGB) texture\n" +
      "  metalnessFactor *= texelMetalness.b;\n" +
      "\n" +
      "#endif";
  }
}