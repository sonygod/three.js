package three.shaderlib;

class BatchingVertex {
    @glsl `
    #ifdef USE_BATCHING
    mat4 batchingMatrix = getBatchingMatrix( batchId );
    #endif
    `;
}