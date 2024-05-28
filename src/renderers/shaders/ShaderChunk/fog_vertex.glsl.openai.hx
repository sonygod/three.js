package three.js.src.renderers.shaders.ShaderChunk;

class FogVertex {
  public static var shader:String = "
#ifdef USE_FOG

	vFogDepth = - mvPosition.z;

#endif
";
}