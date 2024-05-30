package three.renderers.shaders.ShaderChunk;

@:build(macro.ShaderChunkMacro.build("skinbase_vertex.glsl"))
class SkinbaseVertex {

  static var fragment = [
    "#ifdef USE_SKINNING",
    "",
    "\tmat4 boneMatX = getBoneMatrix( skinIndex.x );",
    "\tmat4 boneMatY = getBoneMatrix( skinIndex.y );",
    "\tmat4 boneMatZ = getBoneMatrix( skinIndex.z );",
    "\tmat4 boneMatW = getBoneMatrix( skinIndex.w );",
    "",
    "#endif"
  ].join("\n");

}