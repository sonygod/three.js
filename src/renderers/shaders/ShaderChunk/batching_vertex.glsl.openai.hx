package three.shader;

class BatchingVertex {
  static public var shader:String = `
#ifdef USE_BATCHING
	mat4 batchingMatrix = getBatchingMatrix( batchId );
#endif
  `;
}