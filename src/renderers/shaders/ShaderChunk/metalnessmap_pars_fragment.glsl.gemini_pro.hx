class Shader {
  public static function main(): String {
    return 
      "#ifdef USE_METALNESSMAP\n" +
      "\n" +
      "	uniform sampler2D metalnessMap;\n" +
      "\n" +
      "#endif\n";
  }
}