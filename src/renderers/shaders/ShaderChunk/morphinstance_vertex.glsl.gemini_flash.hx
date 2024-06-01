class Main {
  public static function main(): Void {
    // Haxe doesn't have a direct equivalent of JavaScript template literals with GLSL code.
    // You'll typically use a String to represent your shader code.

    var glslCode: String = "#ifdef USE_INSTANCING_MORPH\n" +
      "\tfloat morphTargetInfluences[ MORPHTARGETS_COUNT ];\n" +
      "\tfloat morphTargetBaseInfluence = texelFetch( morphTexture, ivec2( 0, gl_InstanceID ), 0 ).r;\n" +
      "\tfor ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {\n" +
      "\t\tmorphTargetInfluences[i] =  texelFetch( morphTexture, ivec2( i + 1, gl_InstanceID ), 0 ).r;\n" +
      "\t}\n" +
      "#endif\n";

    // Now you can use the 'glslCode' string to pass to your shader program.
  }
}