package three.src.renderers.shaders.ShaderChunk;

@:build(macro.ShaderChunkMacro.build("normal_fragment_maps.glsl"))
class NormalFragmentMaps {

	static var fragment =
		"#ifdef USE_NORMALMAP_OBJECTSPACE\n" +
		"\tnormal = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0; // overrides both flatShading and attribute normals\n" +
		"\n" +
		"\t#ifdef FLIP_SIDED\n" +
		"\t\tnormal = - normal;\n" +
		"\t#endif\n" +
		"\n" +
		"\t#ifdef DOUBLE_SIDED\n" +
		"\t\tnormal = normal * faceDirection;\n" +
		"\t#endif\n" +
		"\n" +
		"\tnormal = normalize( normalMatrix * normal );\n" +
		"\n" +
		"#elif defined( USE_NORMALMAP_TANGENTSPACE )\n" +
		"\tvec3 mapN = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;\n" +
		"\tmapN.xy *= normalScale;\n" +
		"\n" +
		"\tnormal = normalize( tbn * mapN );\n" +
		"\n" +
		"#elif defined( USE_BUMPMAP )\n" +
		"\tnormal = perturbNormalArb( - vViewPosition, normal, dHdxy_fwd(), faceDirection );\n" +
		"\n" +
		"#endif";

}