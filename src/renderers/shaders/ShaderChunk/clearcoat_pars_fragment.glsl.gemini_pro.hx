class Glsl {
  static function get() {
    var code = "";
    code += "#ifdef USE_CLEARCOATMAP\n";
    code += "\tuniform sampler2D clearcoatMap;\n";
    code += "#endif\n";
    code += "#ifdef USE_CLEARCOAT_NORMALMAP\n";
    code += "\tuniform sampler2D clearcoatNormalMap;\n";
    code += "\tuniform vec2 clearcoatNormalScale;\n";
    code += "#endif\n";
    code += "#ifdef USE_CLEARCOAT_ROUGHNESSMAP\n";
    code += "\tuniform sampler2D clearcoatRoughnessMap;\n";
    code += "#endif\n";
    return code;
  }
}