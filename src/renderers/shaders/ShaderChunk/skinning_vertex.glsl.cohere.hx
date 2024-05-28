#if USE_SKINNING

	var skinVertex = bindMatrix * vec4(transformed, 1.0);

	var skinned = vec4(0.0);
	skinned += boneMatX * skinVertex * skinWeight.x;
	skinned += boneMatY * skinVertex * skinWeight.y;
	skinned += boneMatZ * skinVertex * skinWeight.z;
	skinned += boneMatW * skinVertex * skinWeight.w;

	transformed = (bindMatrixInverse * skinned).xyz;

#end