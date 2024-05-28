package three.renderers.shaders.ShaderChunk;

#if (defined(USE_SHADOWMAP) && (NUM_DIR_LIGHT_SHADOWS > 0 || NUM_POINT_LIGHT_SHADOWS > 0)) || (NUM_SPOT_LIGHT_COORDS > 0)

var shadowWorldNormal:Vec3 = inverseTransformDirection(transformedNormal, viewMatrix);
var shadowWorldPosition:Vec4;

#end

#if defined(USE_SHADOWMAP)

#if NUM_DIR_LIGHT_SHADOWS > 0

for (i in 0...NUM_DIR_LIGHT_SHADOWS) {
    shadowWorldPosition = worldPosition + new Vec4(shadowWorldNormal * directionalLightShadows[i].shadowNormalBias, 0);
    vDirectionalShadowCoord[i] = directionalShadowMatrix[i] * shadowWorldPosition;
}

#end

#if NUM_POINT_LIGHT_SHADOWS > 0

for (i in 0...NUM_POINT_LIGHT_SHADOWS) {
    shadowWorldPosition = worldPosition + new Vec4(shadowWorldNormal * pointLightShadows[i].shadowNormalBias, 0);
    vPointShadowCoord[i] = pointShadowMatrix[i] * shadowWorldPosition;
}

#end

// #if NUM_RECT_AREA_LIGHTS > 0
// TODO: update vAreaShadowCoord with area light info
// #end

#end

// spot lights can be evaluated without active shadow mapping (when SpotLight.map is used)

#if NUM_SPOT_LIGHT_COORDS > 0

for (i in 0...NUM_SPOT_LIGHT_COORDS) {
    shadowWorldPosition = worldPosition;
    #if (defined(USE_SHADOWMAP) && i < NUM_SPOT_LIGHT_SHADOWS)
    shadowWorldPosition.xyz += shadowWorldNormal * spotLightShadows[i].shadowNormalBias;
    #end
    vSpotLightCoord[i] = spotLightMatrix[i] * shadowWorldPosition;
}

#end