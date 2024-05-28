static inline var getBatchingMatrix(batchId:Int):Matrix4 = null;

class BatchingShader {
    public static var code:String = '#ifdef USE_BATCHING \n mat4 batchingMatrix = getBatchingMatrix( batchId ); \n #endif';
}