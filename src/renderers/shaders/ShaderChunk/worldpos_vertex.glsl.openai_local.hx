// 在 Haxe 中导出 GLSL 代码的等效文件
class WorldPosVertexGLSL {
    public static inline var shader: String = '
        #if defined( USE_ENVMAP ) || defined( DISTANCE ) || defined ( USE_SHADOWMAP ) || defined ( USE_TRANSMISSION ) || NUM_SPOT_LIGHT_COORDS > 0

            vec4 worldPosition = vec4( transformed, 1.0 );

            #ifdef USE_BATCHING

                worldPosition = batchingMatrix * worldPosition;

            #endif

            #ifdef USE_INSTANCING

                worldPosition = instanceMatrix * worldPosition;

            #endif

            worldPosition = modelMatrix * worldPosition;

        #endif
    ';
}