// glsl

uniform var receiveShadow : Bool;
uniform var ambientLightColor : Vec3<Float>;

#if defined( USE_LIGHT_PROBES )

	uniform var lightProbe : Array<Vec3<Float>>;

#end

// get the irradiance (radiance convolved with cosine lobe) at the point 'normal' on the unit sphere
// source: https://graphics.stanford.edu/papers/envmap/envmap.pdf
inline function shGetIrradianceAt(normal : Vec3<Float>, shCoefficients : Array<Vec3<Float>>) : Vec3<Float> {

	// normal is assumed to have unit length

	var x = normal.x;
	var y = normal.y;
	var z = normal.z;

	// band 0
	var result = shCoefficients[0] * 0.886227;

	// band 1
	result += shCoefficients[1] * 2.0 * 0.511664 * y;
	result += shCoefficients[2] * 2.0 * 0.511664 * z;
	result += shCoefficients[3] * 2.0 * 0.511664 * x;

	// band 2
	result += shCoefficients[4] * 2.0 * 0.429043 * x * y;
	result += shCoefficients[5] * 2.0 * 0.429043 * y * z;
	result += shCoefficients[6] * ( 0.743125 * z * z - 0.247708 );
	result += shCoefficients[7] * 2.0 * 0.429043 * x * z;
	result += shCoefficients[8] * 0.429043 * ( x * x - y * y );

	return result;

}

inline function getLightProbeIrradiance(lightProbe : Array<Vec3<Float>>, normal : Vec3<Float>) : Vec3<Float> {

	var worldNormal = inverseTransformDirection(normal, viewMatrix);

	var irradiance = shGetIrradianceAt(worldNormal, lightProbe);

	return irradiance;

}

inline function getAmbientLightIrradiance(ambientLightColor : Vec3<Float>) : Vec3<Float> {

	var irradiance = ambientLightColor;

	return irradiance;

}

inline function getDistanceAttenuation(lightDistance : Float, cutoffDistance : Float, decayExponent : Float) : Float {

	#if defined ( LEGACY_LIGHTS )

		if (cutoffDistance > 0.0 && decayExponent > 0.0) {

			return pow(saturate(-lightDistance / cutoffDistance + 1.0), decayExponent);

		}

		return 1.0;

	#else

		// based upon Frostbite 3 Moving to Physically-based Rendering
		// page 32, equation 26: E[window1]
		// https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
		var distanceFalloff = 1.0 / max(pow(lightDistance, decayExponent), 0.01);

		if (cutoffDistance > 0.0) {

			distanceFalloff *= pow2(saturate(1.0 - pow4(lightDistance / cutoffDistance)));

		}

		return distanceFalloff;

	#end

}

inline function getSpotAttenuation(coneCosine : Float, penumbraCosine : Float, angleCosine : Float) : Float {

	return smoothstep(coneCosine, penumbraCosine, angleCosine);

}

#if NUM_DIR_LIGHTS > 0

	struct DirectionalLight {
		direction : Vec3<Float>;
		color : Vec3<Float>;
	}

	uniform var directionalLights : Array<DirectionalLight>;

	inline function getDirectionalLightInfo(directionalLight : DirectionalLight, light : IncidentLight) {

		light.color = directionalLight.color;
		light.direction = directionalLight.direction;
		light.visible = true;

	}

#end


#if NUM_POINT_LIGHTS > 0

	struct PointLight {
		position : Vec3<Float>;
		color : Vec3<Float>;
		distance : Float;
		decay : Float;
	}

	uniform var pointLights : Array<PointLight>;

	// light is an out parameter as having it as a return value caused compiler errors on some devices
	inline function getPointLightInfo(pointLight : PointLight, geometryPosition : Vec3<Float>, light : IncidentLight) {

		var lVector = pointLight.position - geometryPosition;

		light.direction = normalize(lVector);

		var lightDistance = length(lVector);

		light.color = pointLight.color;
		light.color *= getDistanceAttenuation(lightDistance, pointLight.distance, pointLight.decay);
		light.visible = (light.color != Vec3<Float>.zero);

	}

#end


#if NUM_SPOT_LIGHTS > 0

	struct SpotLight {
		position : Vec3<Float>;
		direction : Vec3<Float>;
		color : Vec3<Float>;
		distance : Float;
		decay : Float;
		coneCos : Float;
		penumbraCos : Float;
	}

	uniform var spotLights : Array<SpotLight>;

	// light is an out parameter as having it as a return value caused compiler errors on some devices
	inline function getSpotLightInfo(spotLight : SpotLight, geometryPosition : Vec3<Float>, light : IncidentLight) {

		var lVector = spotLight.position - geometryPosition;

		light.direction = normalize(lVector);

		var angleCos = dot(light.direction, spotLight.direction);

		var spotAttenuation = getSpotAttenuation(spotLight.coneCos, spotLight.penumbraCos, angleCos);

		if (spotAttenuation > 0.0) {

			var lightDistance = length(lVector);

			light.color = spotLight.color * spotAttenuation;
			light.color *= getDistanceAttenuation(lightDistance, spotLight.distance, spotLight.decay);
			light.visible = (light.color != Vec3<Float>.zero);

		} else {

			light.color = Vec3<Float>.zero;
			light.visible = false;

		}

	}

#end


#if NUM_RECT_AREA_LIGHTS > 0

	struct RectAreaLight {
		color : Vec3<Float>;
		position : Vec3<Float>;
		halfWidth : Vec3<Float>;
		halfHeight : Vec3<Float>;
	}

	// Pre-computed values of LinearTransformedCosine approximation of BRDF
	// BRDF approximation Texture is 64x64
	uniform var ltc_1 : Sampler2D; // RGBA Float
	uniform var ltc_2 : Sampler2D; // RGBA Float

	uniform var rectAreaLights : Array<RectAreaLight>;

#end


#if NUM_HEMI_LIGHTS > 0

	struct HemisphereLight {
		direction : Vec3<Float>;
		skyColor : Vec3<Float>;
		groundColor : Vec3<Float>;
	}

	uniform var hemisphereLights : Array<HemisphereLight>;

	inline function getHemisphereLightIrradiance(hemiLight : HemisphereLight, normal : Vec3<Float>) : Vec3<Float> {

		var dotNL = dot(normal, hemiLight.direction);
		var hemiDiffuseWeight = 0.5 * dotNL + 0.5;

		var irradiance = mix(hemiLight.groundColor, hemiLight.skyColor, hemiDiffuseWeight);

		return irradiance;

	}

#end