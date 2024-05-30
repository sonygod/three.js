package three.src.renderers.shaders.ShaderChunk;

@:build(macro.ShaderChunkMacro.build("specularmap_fragment.glsl"))
class SpecularmapFragment {

  static var fragmentShader =
    "float specularStrength;" +
    "#ifdef USE_SPECULARMAP\n" +
    "	vec4 texelSpecular = texture2D( specularMap, vSpecularMapUv );\n" +
    "	specularStrength = texelSpecular.r;\n" +
    "#else\n" +
    "	specularStrength = 1.0;\n" +
    "#endif";

}