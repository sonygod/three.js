#if USE_SKINNING

var skinVertex = bindMatrix * new Float( transformed, 1.0 );

var skinned = new Float( 0.0 );
skinned += boneMatX * skinVertex * skinWeight.x;
skinned += boneMatY * skinVertex * skinWeight.y;
skinned += boneMatZ * skinVertex * skinWeight.z;
skinned += boneMatW * skinVertex * skinWeight.w;

transformed = ( bindMatrixInverse * skinned ).xyz;

#end