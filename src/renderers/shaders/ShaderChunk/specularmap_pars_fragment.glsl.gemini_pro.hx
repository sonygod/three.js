class Shader {
  public static var FRAGMENT_SHADER: String = /* glsl */  """
#ifdef USE_SPECULARMAP

	uniform sampler2D specularMap;

#endif
""";
}