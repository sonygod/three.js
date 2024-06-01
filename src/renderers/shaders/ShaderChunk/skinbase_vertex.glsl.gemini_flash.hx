class Main {
  public static function main(): Void {
    var glsl: String = /* glsl */"";

    glsl += "#ifdef USE_SKINNING\n";
    glsl += "\tmat4 boneMatX = getBoneMatrix( skinIndex.x );\n";
    glsl += "\tmat4 boneMatY = getBoneMatrix( skinIndex.y );\n";
    glsl += "\tmat4 boneMatZ = getBoneMatrix( skinIndex.z );\n";
    glsl += "\tmat4 boneMatW = getBoneMatrix( skinIndex.w );\n";
    glsl += "#endif\n";

    // Use the generated GLSL code (e.g., assign it to a shader)
    trace(glsl); 
  }
}