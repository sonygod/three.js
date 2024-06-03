class ShaderGLSL {
  public static function main(): String {
    return
      '#if defined( USE_LOGDEPTHBUF )\n' +
      '\n' +
      '	uniform float logDepthBufFC;\n' +
      '	varying float vFragDepth;\n' +
      '	varying float vIsPerspective;\n' +
      '\n' +
      '#endif\n';
  }
}