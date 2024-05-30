package three.jsm.csm;

import three.ShaderChunk;

class CSMShader {
    public static var lights_fragment_begin:String = /* glsl */`
vec3 geometryPosition = - vViewPosition;
vec3 geometryNormal = normal;
vec3 geometryViewDir = ( isOrthographic ) ? vec3( 0, 0, 1 ) : normalize( vViewPosition );

vec3 geometryClearcoatNormal = vec3( 0.0 );

#ifdef USE_CLEARCOAT

	geometryClearcoatNormal = clearcoatNormal;

#endif

#ifdef USE_IRIDESCENCE
	float dotNVi = saturate( dot( normal, geometryViewDir ) );
	if ( material.iridescenceThickness == 0.0 ) {
		material.iridescence = 0.0;
	} else {
		material.iridescence = saturate( material.iridescence );
	}
	if ( material.iridescence > 0.0 ) {
		material.iridescenceFresnel = evalIridescence( 1.0, material.iridescenceIOR, dotNVi, material.iridescenceThickness, material.specularColor );
		// Iridescence F0 approximation
		material.iridescenceF0 = Schlick_to_F0( material.iridescenceFresnel, 1.0, dotNVi );
	}
#endif

IncidentLight directLight;

#if ( NUM_POINT_LIGHTS > 0 ) && defined( RE_Direct )

	PointLight pointLight;
	#if defined( USE_SHADOWMAP ) && NUM_POINT_LIGHT_SHADOWS > 0
	PointLightShadow pointLightShadow;
	#endif

	for (i in 0...NUM_POINT_LIGHTS) {

		pointLight = pointLights[i];

		getPointLightInfo(pointLight, geometryPosition, directLight);

		if (i < NUM_POINT_LIGHT_SHADOWS) {
			pointLightShadow = pointLightShadows[i];
			directLight.color *= (directLight.visible && receiveShadow) ? getPointShadow(pointShadowMap[i], pointLightShadow.shadowMapSize, pointLightShadow.shadowBias, pointLightShadow.shadowRadius, vPointShadowCoord[i], pointLightShadow.shadowCameraNear, pointLightShadow.shadowCameraFar) : 1.0;
		}

		RE_Direct(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);

	}

#endif

#if ( NUM_SPOT_LIGHTS > 0 ) && defined( RE_Direct )

	SpotLight spotLight;
 	vec4 spotColor;
	vec3 spotLightCoord;
	bool inSpotLightMap;

	#if defined( USE_SHADOWMAP ) && NUM_SPOT_LIGHT_SHADOWS > 0
	SpotLightShadow spotLightShadow;
	#endif

	for (i in 0...NUM_SPOT_LIGHTS) {

		spotLight = spotLights[i];

		getSpotLightInfo(spotLight, geometryPosition, directLight);

  		// spot lights are ordered [shadows with maps, shadows without maps, maps without shadows, none]
		if (i < NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS) {
			spotLightCoord = vSpotLightCoord[i].xyz / vSpotLightCoord[i].w;
			inSpotLightMap = all(lessThan(abs(spotLightCoord * 2. - 1.), vec3(1.0)));
			spotColor = texture2D(spotLightMap[i], spotLightCoord.xy);
			directLight.color = inSpotLightMap ? directLight.color * spotColor.rgb : directLight.color;
		}

		if (i < NUM_SPOT_LIGHT_SHADOWS) {
			spotLightShadow = spotLightShadows[i];
			directLight.color *= (directLight.visible && receiveShadow) ? getShadow(spotShadowMap[i], spotLightShadow.shadowMapSize, spotLightShadow.shadowBias, spotLightShadow.shadowRadius, vSpotLightCoord[i]) : 1.0;
		}

		RE_Direct(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);

	}

#endif

#if ( NUM_DIR_LIGHTS > 0 ) && defined( RE_Direct ) && defined( USE_CSM ) && defined( CSM_CASCADES )

	DirectionalLight directionalLight;
	float linearDepth = (vViewPosition.z) / (shadowFar - cameraNear);
	#if defined( USE_SHADOWMAP ) && NUM_DIR_LIGHT_SHADOWS > 0
	DirectionalLightShadow directionalLightShadow;
	#endif

	for (i in 0...NUM_DIR_LIGHTS) {

		directionalLight = directionalLights[i];
		getDirectionalLightInfo(directionalLight, directLight);

		if (i < NUM_DIR_LIGHT_SHADOWS) {
			directionalLightShadow = directionalLightShadows[i];
			directLight.color *= (directLight.visible && receiveShadow) ? getShadow(directionalShadowMap[i], directionalLightShadow.shadowMapSize, directionalLightShadow.shadowBias, directionalLightShadow.shadowRadius, vDirectionalShadowCoord[i]) : 1.0;
		}

		RE_Direct(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);

	}

#endif

#if ( NUM_DIR_LIGHTS > 0 ) && defined( RE_Direct ) && !defined( USE_CSM ) && !defined( CSM_CASCADES )

	DirectionalLight directionalLight;
	#if defined( USE_SHADOWMAP ) && NUM_DIR_LIGHT_SHADOWS > 0
	DirectionalLightShadow directionalLightShadow;
	#endif

	for (i in 0...NUM_DIR_LIGHTS) {

		directionalLight = directionalLights[i];

		getDirectionalLightInfo(directionalLight, directLight);

		if (i < NUM_DIR_LIGHT_SHADOWS) {
			directionalLightShadow = directionalLightShadows[i];
			directLight.color *= (directLight.visible && receiveShadow) ? getShadow(directionalShadowMap[i], directionalLightShadow.shadowMapSize, directionalLightShadow.shadowBias, directionalLightShadow.shadowRadius, vDirectionalShadowCoord[i]) : 1.0;
		}

		RE_Direct(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);

	}

#endif

#if ( NUM_RECT_AREA_LIGHTS > 0 ) && defined( RE_Direct_RectArea )

	RectAreaLight rectAreaLight;

	for (i in 0...NUM_RECT_AREA_LIGHTS) {

		rectAreaLight = rectAreaLights[i];
		RE_Direct_RectArea(rectAreaLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);

	}

#endif

#if defined( RE_IndirectDiffuse )

	vec3 iblIrradiance = vec3( 0.0 );

	vec3 irradiance = getAmbientLightIrradiance( ambientLightColor );

	#if defined( USE_LIGHT_PROBES )

		irradiance += getLightProbeIrradiance( lightProbe, geometryNormal );

	#endif

	#if ( NUM_HEMI_LIGHTS > 0 )

		for (i in 0...NUM_HEMI_LIGHTS) {

			irradiance += getHemisphereLightIrradiance( hemisphereLights[i], geometryNormal );

		}

	#endif

#endif

#if defined( RE_IndirectSpecular )

	vec3 radiance = vec3( 0.0 );
	vec3 clearcoatRadiance = vec3( 0.0 );

#endif
` + ShaderChunk.lights_pars_begin;
}