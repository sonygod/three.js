class Shader {
  public static var VERTEX:String = /* glsl */  """
#ifdef USE_DISPLACEMENTMAP

  uniform sampler2D displacementMap;
  uniform float displacementScale;
  uniform float displacementBias;

#endif
""";
}