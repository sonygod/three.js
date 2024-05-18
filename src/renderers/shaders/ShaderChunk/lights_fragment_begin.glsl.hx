package three.shader;

import three.shader.ShaderChunk;

class LightsFragmentBegin {
    static public var shader: String = {
        var geometryPosition: Vec3 = -vViewPosition;
        var geometryNormal: Vec3 = normal;
        var geometryViewDir: Vec3 = isOrthographic ? new Vec3(0, 0, 1) : normalize(vViewPosition);

        var geometryClearcoatNormal: Vec3 = new Vec3(0.0);

        #if USE_CLEARCOAT
            geometryClearcoatNormal = clearcoatNormal;
        #end

        #if USE_IRIDESCENCE
            var dotNVi: Float = saturate(dot(normal, geometryViewDir));

            if (material.iridescenceThickness == 0.0) {
                material.iridescence = 0.0;
            } else {
                material.iridescence = saturate(material.iridescence);
            }

            if (material.iridescence > 0.0) {
                material.iridescenceFresnel = evalIridescence(1.0, material.iridescenceIOR, dotNVi, material.iridescenceThickness, material.specularColor);
                material.iridescenceF0 = Schlick_to_F0(material.iridescenceFresnel, 1.0, dotNVi);
            }
        #end

        var directLight: IncidentLight;

        #if (NUM_POINT_LIGHTS > 0) && defined(RE_Direct)
            var pointLight: PointLight;
            #if defined(USE_SHADOWMAP) && NUM_POINT_LIGHT_SHADOWS > 0
                var pointLightShadow: PointLightShadow;
            #end

            for (i in 0...NUM_POINT_LIGHTS) {
                pointLight = pointLights[i];
                getPointLightInfo(pointLight, geometryPosition, directLight);

                #if defined(USE_SHADOWMAP) && (i < NUM_POINT_LIGHT_SHADOWS)
                    pointLightShadow = pointLightShadows[i];
                    directLight.color *= (directLight.visible && receiveShadow) ? getPointShadow(pointShadowMap[i], pointLightShadow.shadowMapSize, pointLightShadow.shadowBias, pointLightShadow.shadowRadius, vPointShadowCoord[i], pointLightShadow.shadowCameraNear, pointLightShadow.shadowCameraFar) : 1.0;
                #end

                RE_Direct(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
            }
        #end

        #if (NUM_SPOT_LIGHTS > 0) && defined(RE_Direct)
            var spotLight: SpotLight;
            var spotColor: Vec4;
            var spotLightCoord: Vec3;
            var inSpotLightMap: Bool;

            #if defined(USE_SHADOWMAP) && NUM_SPOT_LIGHT_SHADOWS > 0
                var spotLightShadow: SpotLightShadow;
            #end

            for (i in 0...NUM_SPOT_LIGHTS) {
                spotLight = spotLights[i];
                getSpotLightInfo(spotLight, geometryPosition, directLight);

                #if (i < NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS)
                    var spotLightMapIndex: Int = i;
                #elif (i < NUM_SPOT_LIGHT_SHADOWS)
                    var spotLightMapIndex: Int = NUM_SPOT_LIGHT_MAPS;
                #else
                    var spotLightMapIndex: Int = i - NUM_SPOT_LIGHT_SHADOWS + NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS;
                #end

                #if (spotLightMapIndex < NUM_SPOT_LIGHT_MAPS)
                    spotLightCoord = vSpotLightCoord[i].xyz / vSpotLightCoord[i].w;
                    inSpotLightMap = all(lessThan(abs(spotLightCoord * 2. - 1.), new Vec3(1.0)));
                    spotColor = texture2D(spotLightMap[spotLightMapIndex], spotLightCoord.xy);
                    directLight.color = inSpotLightMap ? directLight.color * spotColor.rgb : directLight.color;
                #end

                #if defined(USE_SHADOWMAP) && (i < NUM_SPOT_LIGHT_SHADOWS)
                    spotLightShadow = spotLightShadows[i];
                    directLight.color *= (directLight.visible && receiveShadow) ? getShadow(spotShadowMap[i], spotLightShadow.shadowMapSize, spotLightShadow.shadowBias, spotLightShadow.shadowRadius, vSpotLightCoord[i]) : 1.0;
                #end

                RE_Direct(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
            }
        #end

        #if (NUM_DIR_LIGHTS > 0) && defined(RE_Direct)
            var directionalLight: DirectionalLight;
            #if defined(USE_SHADOWMAP) && NUM_DIR_LIGHT_SHADOWS > 0
                var directionalLightShadow: DirectionalLightShadow;
            #end

            for (i in 0...NUM_DIR_LIGHTS) {
                directionalLight = directionalLights[i];
                getDirectionalLightInfo(directionalLight, directLight);

                #if defined(USE_SHADOWMAP) && (i < NUM_DIR_LIGHT_SHADOWS)
                    directionalLightShadow = directionalLightShadows[i];
                    directLight.color *= (directLight.visible && receiveShadow) ? getShadow(directionalShadowMap[i], directionalLightShadow.shadowMapSize, directionalLightShadow.shadowBias, directionalLightShadow.shadowRadius, vDirectionalShadowCoord[i]) : 1.0;
                #end

                RE_Direct(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
            }
        #end

        #if (NUM_RECT_AREA_LIGHTS > 0) && defined(RE_Direct_RectArea)
            var rectAreaLight: RectAreaLight;

            for (i in 0...NUM_RECT_AREA_LIGHTS) {
                rectAreaLight = rectAreaLights[i];
                RE_Direct_RectArea(rectAreaLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
            }
        #end

        #if defined(RE_IndirectDiffuse)
            var iblIrradiance: Vec3 = new Vec3(0.0);
            var irradiance: Vec3 = getAmbientLightIrradiance(ambientLightColor);

            #if defined(USE_LIGHT_PROBES)
                irradiance += getLightProbeIrradiance(lightProbe, geometryNormal);
            #end

            #if (NUM_HEMI_LIGHTS > 0)
                for (i in 0...NUM_HEMI_LIGHTS) {
                    irradiance += getHemisphereLightIrradiance(hemisphereLights[i], geometryNormal);
                }
            #end
        #end

        #if defined(RE_IndirectSpecular)
            var radiance: Vec3 = new Vec3(0.0);
            var clearcoatRadiance: Vec3 = new Vec3(0.0);
        #end
    };
}