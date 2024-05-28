package three.shaderlib.ShaderChunk;

class MetalnessMapParsFragment {
  public static var SOURCE = '
#ifdef USE_METALNESSMAP

  uniform sampler2D metalnessMap;

#endif
  ';
}