class Main {
  public static function main(): Void {
    // Haxe doesn't have a direct equivalent of template literals with GLSL syntax highlighting.
    // We'll represent the GLSL code as a regular string.
    var glslCode: String = "#ifdef USE_MAP\n" +
      "\tvec4 sampledDiffuseColor = texture2D( map, vMapUv );\n" +
      "\n" +
      "#ifdef DECODE_VIDEO_TEXTURE\n" +
      "\n" +
      "\t// use inline sRGB decode until browsers properly support SRGB8_ALPHA8 with video textures (#26516)\n" +
      "\n" +
      "\tsampledDiffuseColor = vec4( mix( pow( sampledDiffuseColor.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), sampledDiffuseColor.rgb * 0.0773993808, vec3( lessThanEqual( sampledDiffuseColor.rgb, vec3( 0.04045 ) ) ) ), sampledDiffuseColor.w );\n" +
      "\t\n" +
      "#endif\n" +
      "\n" +
      "diffuseColor *= sampledDiffuseColor;\n" +
      "\n" +
      "#endif\n";

  }
}