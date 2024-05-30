package three.renderers.shaders.ShaderChunk;

@:build(macro.ShaderChunkMacro.build("beginnormal_vertex.glsl"))
class BeginNormalVertex {
  static var fragment =
    "vec3 objectNormal = vec3( normal );\n\n" +
    "#ifdef USE_TANGENT\n\n" +
    "	vec3 objectTangent = vec3( tangent.xyz );\n\n" +
    "#endif";
}