class ShaderChunk {
    static var uv_pars_vertex:String = 
        #if defined( USE_UV ) || defined( USE_ANISOTROPY )

            varying vec2 vUv;

        #endif
        #ifdef USE_MAP

            uniform mat3 mapTransform;
            varying vec2 vMapUv;

        #endif
        // ... 其他的GLSL代码
    ;
}