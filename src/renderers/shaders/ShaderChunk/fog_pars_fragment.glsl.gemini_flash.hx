class ShaderGLSL {
  public static function main(): String {
    return /* glsl */
      "#ifdef USE_FOG\n" +
      "\n" +
      "	uniform vec3 fogColor;\n" +
      "	varying float vFogDepth;\n" +
      "\n" +
      "	#ifdef FOG_EXP2\n" +
      "\n" +
      "		uniform float fogDensity;\n" +
      "\n" +
      "	#else\n" +
      "\n" +
      "		uniform float fogNear;\n" +
      "		uniform float fogFar;\n" +
      "\n" +
      "	#endif\n" +
      "\n" +
      "#endif\n";
  }
}