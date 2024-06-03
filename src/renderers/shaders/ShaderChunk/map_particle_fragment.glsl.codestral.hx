package three.js.src.renderers.shaders.ShaderChunk;

class MapParticleFragment {
    public static function getShaderChunk():String {
        return """
        #if defined( USE_MAP ) || defined( USE_ALPHAMAP )

            #if defined( USE_POINTS_UV )

                var uv:Vec2 = vUv;

            #else

                var uv:Vec2 = ( uvTransform * Vec3( gl_PointCoord.x, 1.0 - gl_PointCoord.y, 1 ) ).xy;

            #endif

        #endif

        #ifdef USE_MAP

            diffuseColor *= texture2D( map, uv );

        #endif

        #ifdef USE_ALPHAMAP

            diffuseColor.a *= texture2D( alphaMap, uv ).g;

        #endif
        """;
    }
}