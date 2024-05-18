package renderers.shaders.ShaderChunk;

@:glsl("
#ifdef USE_SKINNING

	mat4 skinMatrix = mat4( 0.0 );
	skinMatrix += skinWeight.x * boneMatX;
	skinMatrix += skinWeight.y * boneMatY;
	skinMatrix += skinWeight.z * boneMatZ;
	skinMatrix += skinWeight.w * boneMatW;
	skinMatrix = bindMatrixInverse * skinMatrix * bindMatrix;

	vec3 objectNormal = vec3( skinMatrix * vec4( objectNormal, 0.0 ) );

	#ifdef USE_TANGENT

		vec3 objectTangent = vec3( skinMatrix * vec4( objectTangent, 0.0 ) );

	#endif

#endif
");