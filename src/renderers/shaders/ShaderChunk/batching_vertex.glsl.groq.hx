package three.renderers.shaders.ShaderChunk;

@:glsl("
#ifdef USE_BATCHING
	mat4 batchingMatrix = getBatchingMatrix( batchId );
#endif
")
class BatchingVertex {}