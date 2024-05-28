package three.js.src.renderers.shaders.ShaderChunk;

// shader code
@:glsl
class ShadowMask {
    public function getShadowMask():Float {
        var shadow:Float = 1.0;

        #if USE_SHADOWMAP

        #if NUM_DIR_LIGHT_SHADOWS > 0

        var directionalLight:DirectionalLightShadow;

        for (i in 0...NUM_DIR_LIGHT_SHADOWS) {
            directionalLight = directionalLightShadows[i];
            shadow *= receiveShadow ? getShadow(directionalShadowMap[i], directionalLight.shadowMapSize, directionalLight.shadowBias, directionalLight.shadowRadius, vDirectionalShadowCoord[i]) : 1.0;
        }

        #endif

        #if NUM_SPOT_LIGHT_SHADOWS > 0

        var spotLight:SpotLightShadow;

        for (i in 0...NUM_SPOT_LIGHT_SHADOWS) {
            spotLight = spotLightShadows[i];
            shadow *= receiveShadow ? getShadow(spotShadowMap[i], spotLight.shadowMapSize, spotLight.shadowBias, spotLight.shadowRadius, vSpotLightCoord[i]) : 1.0;
        }

        #endif

        #if NUM_POINT_LIGHT_SHADOWS > 0

        var pointLight:PointLightShadow;

        for (i in 0...NUM_POINT_LIGHT_SHADOWS) {
            pointLight = pointLightShadows[i];
            shadow *= receiveShadow ? getPointShadow(pointShadowMap[i], pointLight.shadowMapSize, pointLight.shadowBias, pointLight.shadowRadius, vPointShadowCoord[i], pointLight.shadowCameraNear, pointLight.shadowCameraFar) : 1.0;
        }

        #endif

        // #if NUM_RECT_AREA_LIGHTS > 0
        // TODO (abelnation): update shadow for Area light
        // #end

        #end

        return shadow;
    }
}