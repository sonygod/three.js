package three.renderers.shaders.ShaderChunk;

class FogVertex {
  public function new() {}

  public static var shaderSrc(get, never):String;

  private static function get_shaderSrc():String {
    return '
#ifdef USE_FOG

	vFogDepth = - mvPosition.z;

#endif
';
  }
}