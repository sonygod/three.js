class Shader {
  public static function main(): String {
    return
      "#ifdef USE_SPECULARMAP\n" +
      "\n" +
      "	uniform sampler2D specularMap;\n" +
      "\n" +
      "#endif\n";
  }
}