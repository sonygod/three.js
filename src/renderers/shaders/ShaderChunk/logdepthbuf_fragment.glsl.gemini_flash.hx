class Main {
  public static function main(): Void {
    var glsl: String = /* glsl */
      "#if defined( USE_LOGDEPTHBUF )\n" +
      "\n" +
      "	// Doing a strict comparison with == 1.0 can cause noise artifacts\n" +
      "	// on some platforms. See issue #17623.\n" +
      "	gl_FragDepth = (vIsPerspective == 0.0) ? gl_FragCoord.z : log2( vFragDepth ) * logDepthBufFC * 0.5;\n" +
      "\n" +
      "#endif\n";
  }
}