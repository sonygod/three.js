package three.shader;

class ShadowMask {
    public static function getShadowMask():Float {
        var shadow:Float = 1.0;

        #if USE_SHADOWMAP

        #if NUM_DIR_LIGHT_SHADOWS > 0
        for (i in 0...NUM_DIR_LIGHT_SHADOWS) {
            var directionalLight:DirectionalLightShadow = directionalLightShadows[i];
            shadow *= receiveShadow ? getShadow(directionalShadowMap[i], directionalLight.shadowMapSize, directionalLight.shadowBias, directionalLight.shadowRadius, vDirectionalShadowCoord[i]) : 1.0;
        }
        #end

        #if NUM_SPOT_LIGHT_SHADOWS > 0
        for (i in 0...NUM_SPOT_LIGHT_SHADOWS) {
            var spotLight:SpotLightShadow = spotLightShadows[i];
            shadow *= receiveShadow ? getShadow(spotShadowMap[i], spotLight.shadowMapSize, spotLight.shadowBias, spotLight.shadowRadius, vSpotLightCoord[i]) : 1.0;
        }
        #end

        #if NUM_POINT_LIGHT_SHADOWS > 0
        for (i in 0...NUM_POINT_LIGHT_SHADOWS) {
            var pointLight:PointLightShadow = pointLightShadows[i];
            shadow *= receiveShadow ? getPointShadow(pointShadowMap[i], pointLight.shadowMapSize, pointLight.shadowBias, pointLight.shadowRadius, vPointShadowCoord[i], pointLight.shadowCameraNear, pointLight.shadowCameraFar) : 1.0;
        }
        #end

        #endif

        return shadow;
    }
}