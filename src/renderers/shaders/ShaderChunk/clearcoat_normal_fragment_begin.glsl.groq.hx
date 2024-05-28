package three.renderers.shaders.ShaderChunk;

class ClearcoatNormalFragmentBegin {
  public static var shader: String = "
#ifdef USE_CLEARCOAT

	vec3 clearcoatNormal = nonPerturbedNormal;

#endif
";
}