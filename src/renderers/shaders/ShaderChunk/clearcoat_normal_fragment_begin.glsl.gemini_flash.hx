class Shader {
  public static function main(): String {
    return 
"""
#ifdef USE_CLEARCOAT

	vec3 clearcoatNormal = nonPerturbedNormal;

#endif
""";
  }
}