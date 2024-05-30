package three.src.renderers.shaders.ShaderChunk;

@:build(macro.ShaderChunkMacro.build("clearcoat_normal_fragment_maps.glsl"))
class ClearcoatNormalFragmentMaps {

  static var fragmentShader =
    "#ifdef USE_CLEARCOAT_NORMALMAP\n" +
    "\n" +
    "	vec3 clearcoatMapN = texture2D( clearcoatNormalMap, vClearcoatNormalMapUv ).xyz * 2.0 - 1.0;\n" +
    "	clearcoatMapN.xy *= clearcoatNormalScale;\n" +
    "\n" +
    "	clearcoatNormal = normalize( tbn2 * clearcoatMapN );\n" +
    "\n" +
    "#endif\n";

}