@:expose("default")
class Shader {
  public static var source: String = /* glsl */
  """
  #ifdef USE_EMISSIVEMAP

    uniform sampler2D emissiveMap;

  #endif
  """;
}