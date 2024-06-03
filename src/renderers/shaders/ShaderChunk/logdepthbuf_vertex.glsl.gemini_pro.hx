class ShaderGLSL {
  public static function main(): String {
    return 
"""
#ifdef USE_LOGDEPTHBUF

	vFragDepth = 1.0 + gl_Position.w;
	vIsPerspective = float(isPerspectiveMatrix(projectionMatrix));

#endif
""";
  }
}