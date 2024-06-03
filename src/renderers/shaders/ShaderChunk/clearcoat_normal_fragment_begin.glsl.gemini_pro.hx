class Shader {
  public static function main(): String {
    return 
      "#ifdef USE_CLEARCOAT\n" +
      "\n" +
      "	vec3 clearcoatNormal = nonPerturbedNormal;\n" +
      "\n" +
      "#endif\n";
  }
}