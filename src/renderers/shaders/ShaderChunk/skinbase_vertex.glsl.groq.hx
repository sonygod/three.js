package three.shader;

class SkinBaseVertex {
    public static var shader:String = "
#ifdef USE_SKINNING

	vec4 boneMatX = getBoneMatrix(skinIndex.x);
	vec4 boneMatY = getBoneMatrix(skinIndex.y);
	vec4 boneMatZ = getBoneMatrix(skinIndex.z);
	vec4 boneMatW = getBoneMatrix(skinIndex.w);

#endif
";
}