class Shader {
  public static var source = /* glsl */"
#ifdef USE_LOGDEPTHBUF

	varying float vFragDepth;
	varying float vIsPerspective;

#endif
";
}