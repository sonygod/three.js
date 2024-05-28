var boneMatX:Mat4, boneMatY:Mat4, boneMatZ:Mat4, boneMatW:Mat4;
#if USE_SKINNING
	boneMatX = getBoneMatrix(skinIndex.x);
	boneMatY = getBoneMatrix(skinIndex.y);
	boneMatZ = getBoneMatrix(skinIndex.z);
	boneMatW = getBoneMatrix(skinIndex.w);
#end