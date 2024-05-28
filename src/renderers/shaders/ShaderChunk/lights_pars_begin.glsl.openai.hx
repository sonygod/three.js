@:glsl
class LightsParsBegin {
  // Uniforms
  @:uniform var receiveShadow:Bool;
  @:uniform var ambientLightColor:Vec3;

  #if defined(USE_LIGHT_PROBES)
  @:uniform var lightProbe:Array<Vec3>;
  #end

  // Functions
  function shGetIrradianceAt(normal:Vec3, shCoefficients:Array<Vec3>):Vec3 {
    // normal is assumed to have unit length
    var x:Float = normal.x;
    var y:Float = normal.y;
    var z:Float = normal.z;

    var result:Vec3 = shCoefficients[0] * 0.886227;

    // band 1
    result += shCoefficients[1] * 2.0 * 0.511664 * y;
    result += shCoefficients[2] * 2.0 * 0.511664 * z;
    result += shCoefficients[3] * 2.0 * 0.511664 * x;

    // band 2
    result += shCoefficients[4] * 2.0 * 0.429043 * x * y;
    result += shCoefficients[5] * 2.0 * 0.429043 * y * z;
    result += shCoefficients[6] * (0.743125 * z * z - 0.247708);
    result += shCoefficients[7] * 2.0 * 0.429043 * x * z;
    result += shCoefficients[8] * 0.429043 * (x * x - y * y);

    return result;
  }

  function getLightProbeIrradiance(lightProbe:Array<Vec3>, normal:Vec3):Vec3 {
    var worldNormal:Vec3 = inverseTransformDirection(normal, viewMatrix);

    var irradiance:Vec3 = shGetIrradianceAt(worldNormal, lightProbe);

    return irradiance;
  }

  function getAmbientLightIrradiance(ambientLightColor:Vec3):Vec3 {
    var irradiance:Vec3 = ambientLightColor;

    return irradiance;
  }

  function getDistanceAttenuation(lightDistance:Float, cutoffDistance:Float, decayExponent:Float):Float {
    #if defined(LEGACY_LIGHTS)
    if (cutoffDistance > 0.0 && decayExponent > 0.0) {
      return pow(saturate(-lightDistance / cutoffDistance + 1.0), decayExponent);
    }
    return 1.0;
    #else
    var distanceFalloff:Float = 1.0 / max(pow(lightDistance, decayExponent), 0.01);

    if (cutoffDistance > 0.0) {
      distanceFalloff *= pow2(saturate(1.0 - pow4(lightDistance / cutoffDistance)));
    }

    return distanceFalloff;
    #end
  }

  function getSpotAttenuation(coneCosine:Float, penumbraCosine:Float, angleCosine:Float):Float {
    return smoothstep(coneCosine, penumbraCosine, angleCosine);
  }

  // Directional Light
  #if NUM_DIR_LIGHTS > 0
  struct DirectionalLight {
    var direction:Vec3;
    var color:Vec3;
  }

  @:uniform var directionalLights:Array<DirectionalLight>;

  function getDirectionalLightInfo(directionalLight:DirectionalLight, out light:IncidentLight) {
    light.color = directionalLight.color;
    light.direction = directionalLight.direction;
    light.visible = true;
  }
  #end

  // Point Light
  #if NUM_POINT_LIGHTS > 0
  struct PointLight {
    var position:Vec3;
    var color:Vec3;
    var distance:Float;
    var decay:Float;
  }

  @:uniform var pointLights:Array<PointLight>;

  function getPointLightInfo(pointLight:PointLight, geometryPosition:Vec3, out light:IncidentLight) {
    var lVector:Vec3 = pointLight.position - geometryPosition;

    light.direction = normalize(lVector);

    var lightDistance:Float = length(lVector);

    light.color = pointLight.color;
    light.color *= getDistanceAttenuation(lightDistance, pointLight.distance, pointLight.decay);
    light.visible = (light.color != Vec3.zero);
  }
  #end

  // Spot Light
  #if NUM_SPOT_LIGHTS > 0
  struct SpotLight {
    var position:Vec3;
    var direction:Vec3;
    var color:Vec3;
    var distance:Float;
    var decay:Float;
    var coneCos:Float;
    var penumbraCos:Float;
  }

  @:uniform var spotLights:Array<SpotLight>;

  function getSpotLightInfo(spotLight:SpotLight, geometryPosition:Vec3, out light:IncidentLight) {
    var lVector:Vec3 = spotLight.position - geometryPosition;

    light.direction = normalize(lVector);

    var angleCos:Float = dot(light.direction, spotLight.direction);

    var spotAttenuation:Float = getSpotAttenuation(spotLight.coneCos, spotLight.penumbraCos, angleCos);

    if (spotAttenuation > 0.0) {
      var lightDistance:Float = length(lVector);

      light.color = spotLight.color * spotAttenuation;
      light.color *= getDistanceAttenuation(lightDistance, spotLight.distance, spotLight.decay);
      light.visible = (light.color != Vec3.zero);
    } else {
      light.color = Vec3.zero;
      light.visible = false;
    }
  }
  #end

  // Rect Area Light
  #if NUM_RECT_AREA_LIGHTS > 0
  struct RectAreaLight {
    var color:Vec3;
    var position:Vec3;
    var halfWidth:Vec3;
    var halfHeight:Vec3;
  }

  @:uniform var rectAreaLights:Array<RectAreaLight>;

  @:uniform var ltc_1:Texture;
  @:uniform var ltc_2:Texture;
  #end

  // Hemisphere Light
  #if NUM_HEMI_LIGHTS > 0
  struct HemisphereLight {
    var direction:Vec3;
    var skyColor:Vec3;
    var groundColor:Vec3;
  }

  @:uniform var hemisphereLights:Array<HemisphereLight>;

  function getHemisphereLightIrradiance(hemiLight:HemisphereLight, normal:Vec3):Vec3 {
    var dotNL:Float = dot(normal, hemiLight.direction);
    var hemiDiffuseWeight:Float = 0.5 * dotNL + 0.5;

    var irradiance:Vec3 = mix(hemiLight.groundColor, hemiLight.skyColor, hemiDiffuseWeight);

    return irradiance;
  }
  #end
}