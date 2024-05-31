class Shader {
  public static function main(): String {
    return
      "#ifdef USE_FOG\n" +
      "\n" +
      "	varying float vFogDepth;\n" +
      "\n" +
      "#endif\n";
  }
}