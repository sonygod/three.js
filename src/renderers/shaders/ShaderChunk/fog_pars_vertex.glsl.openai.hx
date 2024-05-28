package three.js.src.renderers.shaders.ShaderChunk;

class FogParsVertex {
  static var shaderCode:String = '
#ifdef USE_FOG

  varying float vFogDepth;

#endif
  ';
}