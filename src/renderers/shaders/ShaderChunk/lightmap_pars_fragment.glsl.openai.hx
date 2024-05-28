package three.renderers.shaders.ShaderChunk;

class LightmapParsFragment {
  public static var shader: String = '
#ifdef USE_LIGHTMAP

  uniform sampler2D lightMap;
  uniform float lightMapIntensity;

#endif
  ';
}