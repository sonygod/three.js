package three.shader.chunks;

class ShadowmapParsVertex {
    @-glsl
    public static var code:String = '

#if NUM_SPOT_LIGHT_COORDS > 0

    uniform mat4 spotLightMatrix[NUM_SPOT_LIGHT_COORDS];
    varying vec4 vSpotLightCoord[NUM_SPOT_LIGHT_COORDS];

#endif

#ifdef USE_SHADOWMAP

    #if NUM_DIR_LIGHT_SHADOWS > 0

        uniform mat4 directionalShadowMatrix[NUM_DIR_LIGHT_SHADOWS];
        varying vec4 vDirectionalShadowCoord[NUM_DIR_LIGHT_SHADOWS];

        struct DirectionalLightShadow {
            var shadowBias:Float;
            var shadowNormalBias:Float;
            var shadowRadius:Float;
            var shadowMapSize:Vec2;
        };

        uniform var directionalLightShadows:Array<DirectionalLightShadow> = [for (i in 0...NUM_DIR_LIGHT_SHADOWS) new DirectionalLightShadow()];

    #endif

    #if NUM_SPOT_LIGHT_SHADOWS > 0

        struct SpotLightShadow {
            var shadowBias:Float;
            var shadowNormalBias:Float;
            var shadowRadius:Float;
            var shadowMapSize:Vec2;
        };

        uniform var spotLightShadows:Array<SpotLightShadow> = [for (i in 0...NUM_SPOT_LIGHT_SHADOWS) new SpotLightShadow()];

    #endif

    #if NUM_POINT_LIGHT_SHADOWS > 0

        uniform mat4 pointShadowMatrix[NUM_POINT_LIGHT_SHADOWS];
        varying vec4 vPointShadowCoord[NUM_POINT_LIGHT_SHADOWS];

        struct PointLightShadow {
            var shadowBias:Float;
            var shadowNormalBias:Float;
            var shadowRadius:Float;
            var shadowMapSize:Vec2;
            var shadowCameraNear:Float;
            var shadowCameraFar:Float;
        };

        uniform var pointLightShadows:Array<PointLightShadow> = [for (i in 0...NUM_POINT_LIGHT_SHADOWS) new PointLightShadow()];

    #endif

    /* 
    #if NUM_RECT_AREA_LIGHTS > 0

        // TODO (abelnation): uniforms for area light shadows

    #endif
    */

#endif
';
}