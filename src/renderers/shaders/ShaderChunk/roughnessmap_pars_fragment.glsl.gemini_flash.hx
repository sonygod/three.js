class Shader {
  public static function main(): String {
    return '#ifdef USE_ROUGHNESSMAP\n' +
           '\tuniform sampler2D roughnessMap;\n' +
           '#endif\n';
  }
}