// 文件路径: three/src/renderers/shaders/ShaderChunk/skinbase_vertex.glsl.hx

package three.renderers.shaders.ShaderChunk;

class SkinbaseVertexGLSL {
    public static inline var source = '
        #ifdef USE_SKINNING

            mat4 boneMatX = getBoneMatrix( skinIndex.x );
            mat4 boneMatY = getBoneMatrix( skinIndex.y );
            mat4 boneMatZ = getBoneMatrix( skinIndex.z );
            mat4 boneMatW = getBoneMatrix( skinIndex.w );

        #endif
    ';
}