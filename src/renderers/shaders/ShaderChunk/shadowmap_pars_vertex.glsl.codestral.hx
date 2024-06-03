// Haxe does not have a direct equivalent for JavaScript's export default, so we'll just define it as a constant.
var SHADER_CHUNK_SHADOWMAP_PARS_VERTEX = """

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
            var shadowMapSize:haxe.ds.Vector<Float>;
        }

        uniform DirectionalLightShadow directionalLightShadows[NUM_DIR_LIGHT_SHADOWS];

    #endif

    #if NUM_SPOT_LIGHT_SHADOWS > 0

        struct SpotLightShadow {
            var shadowBias:Float;
            var shadowNormalBias:Float;
            var shadowRadius:Float;
            var shadowMapSize:haxe.ds.Vector<Float>;
        }

        uniform SpotLightShadow spotLightShadows[NUM_SPOT_LIGHT_SHADOWS];

    #endif

    #if NUM_POINT_LIGHT_SHADOWS > 0

        uniform mat4 pointShadowMatrix[NUM_POINT_LIGHT_SHADOWS];
        varying vec4 vPointShadowCoord[NUM_POINT_LIGHT_SHADOWS];

        struct PointLightShadow {
            var shadowBias:Float;
            var shadowNormalBias:Float;
            var shadowRadius:Float;
            var shadowMapSize:haxe.ds.Vector<Float>;
            var shadowCameraNear:Float;
            var shadowCameraFar:Float;
        }

        uniform PointLightShadow pointLightShadows[NUM_POINT_LIGHT_SHADOWS];

    #endif

    /*
    #if NUM_RECT_AREA_LIGHTS > 0

        // TODO (abelnation): uniforms for area light shadows

    #endif
    */

#endif
""";