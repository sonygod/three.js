package three.shader;

abstract AlphabetaparsFragmentGlsl(String) from String {
  public inline function new() {
    this = '
#ifdef USE_ALPHAMAP

  uniform sampler2D alphaMap;

#endif
    ';
  }
}