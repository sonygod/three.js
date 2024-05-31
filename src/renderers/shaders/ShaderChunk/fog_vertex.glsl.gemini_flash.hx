class Shader {
  public static function main(): String {
    return 
      "#ifdef USE_FOG\n" +
      "\tvFogDepth = - mvPosition.z;\n" + 
      "#endif\n";
  }
}