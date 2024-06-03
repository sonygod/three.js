class ShaderChunk_shadowmask_pars_fragment {
    public static function getShadowMask():Float {
        var shadow:Float = 1.0;

        // Haxe does not support preprocessor directives, so these checks are not possible
        // You would need to handle these cases in your Haxe code elsewhere

        // #ifdef USE_SHADOWMAP

        // #if NUM_DIR_LIGHT_SHADOWS > 0
        for (i in 0...NUM_DIR_LIGHT_SHADOWS) {
            var directionalLight = directionalLightShadows[i];
            shadow *= receiveShadow ? getShadow(directionalShadowMap[i], directionalLight.shadowMapSize, directionalLight.shadowBias, directionalLight.shadowRadius, vDirectionalShadowCoord[i]) : 1.0;
        }
        // #endif

        // #if NUM_SPOT_LIGHT_SHADOWS > 0
        for (i in 0...NUM_SPOT_LIGHT_SHADOWS) {
            var spotLight = spotLightShadows[i];
            shadow *= receiveShadow ? getShadow(spotShadowMap[i], spotLight.shadowMapSize, spotLight.shadowBias, spotLight.shadowRadius, vSpotLightCoord[i]) : 1.0;
        }
        // #endif

        // #if NUM_POINT_LIGHT_SHADOWS > 0
        for (i in 0...NUM_POINT_LIGHT_SHADOWS) {
            var pointLight = pointLightShadows[i];
            shadow *= receiveShadow ? getPointShadow(pointShadowMap[i], pointLight.shadowMapSize, pointLight.shadowBias, pointLight.shadowRadius, vPointShadowCoord[i], pointLight.shadowCameraNear, pointLight.shadowCameraFar) : 1.0;
        }
        // #endif

        // #endif

        return shadow;
    }
}