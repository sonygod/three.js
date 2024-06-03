class ShaderChunk_clipping_planes_pars_vertex {
  static function toString():String {
    return """
#if NUM_CLIPPING_PLANES > 0

	varying vec3 vClipPosition;

#endif
""";
  }
}