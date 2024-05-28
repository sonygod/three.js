package three.js.src.renderers.shaders.ShaderChunk;

/**
 * This is a template that can be used to light a material, it uses pluggable
 * RenderEquations (RE)for specific lighting scenarios.
 *
 * Instructions for use:
 * - Ensure that both RE_Direct, RE_IndirectDiffuse and RE_IndirectSpecular are defined
 * - Create a material parameter that is to be passed as the third parameter to your lighting functions.
 *
 * TODO:
 * - Add area light support.
 * - Add sphere light support.
 * - Add diffuse light probe (irradiance cubemap) support.
 */

var geometryPosition : Vec3 = -vViewPosition;
var geometryNormal : Vec3 = normal;
var geometryViewDir : Vec3 = (isOrthographic) ? new Vec3(0, 0, 1) : Vec3.normalize(vViewPosition);

var geometryClearcoatNormal : Vec3 = new Vec3(0.0);

#if USE_CLEARCOAT
geometryClearcoatNormal = clearcoatNormal;
#end

#if USE_IRIDESCENCE
var dotNVi : Float = saturate(dot(normal, geometryViewDir));

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

var directLight : IncidentLight;

#if (NUM_POINT_LIGHTS > 0) && defined(RE_Direct)
var pointLight : PointLight;
#if defined(USE_SHADOWMAP) && NUM_POINT_LIGHT_SHADOWS > 0
var pointLightShadow : PointLightShadow;
#end

for (i in 0...NUM_POINT_LIGHTS) {
    pointLight = pointLights[i];
    getPointLightInfo(pointLight, geometryPosition, directLight);
    #if defined(USE_SHADOWMAP) && (UNROLLED_LOOP_INDEX < NUM_POINT_LIGHT_SHADOWS)
    pointLightShadow = pointLightShadows[i];
    directLight.color *= (directLight.visible && receiveShadow) ? getPointShadow(pointShadowMap[i], pointLightShadow.shadowMapSize, pointLightShadow.shadowBias, pointLightShadow.shadowRadius, vPointShadowCoord[i], pointLightShadow.shadowCameraNear, pointLightShadow.shadowCameraFar) : 1.0;
    #end
    RE_Direct(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
}

#end

#if (NUM_SPOT_LIGHTS > 0) && defined(RE_Direct)
var spotLight : SpotLight;
var spotColor : Vec4;
var spotLightCoord : Vec3;
var inSpotLightMap : Bool;

#if defined(USE_SHADOWMAP) && NUM_SPOT_LIGHT_SHADOWS > 0
var spotLightShadow : SpotLightShadow;
#end

for (i in 0...NUM_SPOT_LIGHTS) {
    spotLight = spotLights[i];
    getSpotLightInfo(spotLight, geometryPosition, directLight);
    // spot lights are ordered [shadows with maps, shadows without maps, maps without shadows, none]
    #if (UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS)
    #define SPOT_LIGHT_MAP_INDEX UNROLLED_LOOP_INDEX
    #elif (UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS)
    #define SPOT_LIGHT_MAP_INDEX NUM_SPOT_LIGHT_MAPS
    #else
    #define SPOT_LIGHT_MAP_INDEX (UNROLLED_LOOP_INDEX - NUM_SPOT_LIGHT_SHADOWS + NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS)
    #end

    #if (SPOT_LIGHT_MAP_INDEX < NUM_SPOT_LIGHT_MAPS)
    spotLightCoord = vSpotLightCoord[i].xyz / vSpotLightCoord[i].w;
    inSpotLightMap = all(lessThan(abs(spotLightCoord * 2. - 1.), vec3(1.0)));
    spotColor = texture2D(spotLightMap[SPOT_LIGHT_MAP_INDEX], spotLightCoord.xy);
    directLight.color = inSpotLightMap ? directLight.color * spotColor.rgb : directLight.color;
    #end

    #undef SPOT_LIGHT_MAP_INDEX

    #if defined(USE_SHADOWMAP) && (UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS)
    spotLightShadow = spotLightShadows[i];
    directLight.color *= (directLight.visible && receiveShadow) ? getShadow(spotShadowMap[i], spotLightShadow.shadowMapSize, spotLightShadow.shadowBias, spotLightShadow.shadowRadius, vSpotLightCoord[i]) : 1.0;
    #end
    RE_Direct(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
}
#end

#if (NUM_DIR_LIGHTS > 0) && defined(RE_Direct)
var directionalLight : DirectionalLight;
#if defined(USE_SHADOWMAP) && NUM_DIR_LIGHT_SHADOWS > 0
var directionalLightShadow : DirectionalLightShadow;
#end

for (i in 0...NUM_DIR_LIGHTS) {
    directionalLight = directionalLights[i];
    getDirectionalLightInfo(directionalLight, directLight);
    #if defined(USE_SHADOWMAP) && (UNROLLED_LOOP_INDEX < NUM_DIR_LIGHT_SHADOWS)
    directionalLightShadow = directionalLightShadows[i];
    directLight.color *= (directLight.visible && receiveShadow) ? getShadow(directionalShadowMap[i], directionalLightShadow.shadowMapSize, directionalLightShadow.shadowBias, directionalLightShadow.shadowRadius, vDirectionalShadowCoord[i]) : 1.0;
    #end
    RE_Direct(directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
}
#end

#if (NUM_RECT_AREA_LIGHTS > 0) && defined(RE_Direct_RectArea)
var rectAreaLight : RectAreaLight;

for (i in 0...NUM_RECT_AREA_LIGHTS) {
    rectAreaLight = rectAreaLights[i];
    RE_Direct_RectArea(rectAreaLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight);
}
#end

#if defined(RE_IndirectDiffuse)
var iblIrradiance : Vec3 = new Vec3(0.0);
var irradiance : Vec3 = getAmbientLightIrradiance(ambientLightColor);

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
var radiance : Vec3 = new Vec3(0.0);
var clearcoatRadiance : Vec3 = new Vec3(0.0);
#end