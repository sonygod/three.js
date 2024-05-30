package three.renderers.shaders.ShaderChunk;

@:build(macro.ShaderChunkMacro.build("fog_vertex.glsl"))
class FogVertex {
  static var fragment =
    "#ifdef USE_FOG\n" +
    "\tvFogDepth = - mvPosition.z;\n" +
    "#endif";
}