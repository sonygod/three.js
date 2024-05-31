class ShaderChunk {
  public static function USE_LIGHTMAP():String {
    return /* glsl */
"""
#ifdef USE_LIGHTMAP

  uniform sampler2D lightMap;
  uniform float lightMapIntensity;

#endif
""";
  }
}