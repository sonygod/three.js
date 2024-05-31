class Shader {
  public static function main(): String {
    return 
      '#ifdef USE_ALPHAHASH\n' +
      '  if (diffuseColor.a < getAlphaHashThreshold(vPosition)) discard;\n' + 
      '#endif\n';
  }
}