package three.shader;

import haxe.ds.Vector;

using Math;

class LightsParsBegin {
    public static var receiveShadow:Bool;
    public static var ambientLightColor:Vector<Float>;

#if USE_LIGHT_PROBES
    public static var lightProbe:Array<Vector<Float>> = [for (i in 0...9) new Vector<Float>(3)];
#end

    public static function shGetIrradianceAt(normal:Vector<Float>, shCoefficients:Array<Vector<Float>>):Vector<Float> {
        // normal is assumed to have unit length
        var x:Float = normal[0];
        var y:Float = normal[1];
        var z:Float = normal[2];

        // band 0
        var result:Vector<Float> = shCoefficients[0].clone();
        result.scale(0.886227);

        // band 1
        result.addScaledVector(shCoefficients[1], 2.0 * 0.511664 * y);
        result.addScaledVector(shCoefficients[2], 2.0 * 0.511664 * z);
        result.addScaledVector(shCoefficients[3], 2.0 * 0.511664 * x);

        // band 2
        result.addScaledVector(shCoefficients[4], 2.0 * 0.429043 * x * y);
        result.addScaledVector(shCoefficients[5], 2.0 * 0.429043 * y * z);
        result.addScaledVector(shCoefficients[6], 0.743125 * z * z - 0.247708);
        result.addScaledVector(shCoefficients[7], 2.0 * 0.429043 * x * z);
        result.addScaledVector(shCoefficients[8], 0.429043 * (x * x - y * y));

        return result;
    }

    public static function getLightProbeIrradiance(lightProbe:Array<Vector<Float>>, normal:Vector<Float>):Vector<Float> {
        var worldNormal:Vector<Float> = inverseTransformDirection(normal, viewMatrix);
        var irradiance:Vector<Float> = shGetIrradianceAt(worldNormal, lightProbe);
        return irradiance;
    }

    public static function getAmbientLightIrradiance(ambientLightColor:Vector<Float>):Vector<Float> {
        var irradiance:Vector<Float> = ambientLightColor.clone();
        return irradiance;
    }

    public static function getDistanceAttenuation(lightDistance:Float, cutoffDistance:Float, decayExponent:Float):Float {
#if LEGACY_LIGHTS
        if (cutoffDistance > 0.0 && decayExponent > 0.0) {
            return Math.pow(Math.max(1.0 - lightDistance / cutoffDistance, 0.0), decayExponent);
        }
        return 1.0;
#else
        var distanceFalloff:Float = 1.0 / Math.max(Math.pow(lightDistance, decayExponent), 0.01);
        if (cutoffDistance > 0.0) {
            distanceFalloff *= Math.pow(Math.max(1.0 - Math.pow4(lightDistance / cutoffDistance), 0.0), 2);
        }
        return distanceFalloff;
#end
    }

    public static function getSpotAttenuation(coneCosine:Float, penumbraCosine:Float, angleCosine:Float):Float {
        return Math.smoothstep(coneCosine, penumbraCosine, angleCosine);
    }

#if NUM_DIR_LIGHTS > 0
    public static var directionalLights:Array<DirectionalLight> = [for (i in 0...NUM_DIR_LIGHTS) new DirectionalLight()];

    public static function getDirectionalLightInfo(directionalLight:DirectionalLight, light:IncidentLight) {
        light.color = directionalLight.color;
        light.direction = directionalLight.direction;
        light.visible = true;
    }
#end

#if NUM_POINT_LIGHTS > 0
    public static var pointLights:Array<PointLight> = [for (i in 0...NUM_POINT_LIGHTS) new PointLight()];

    public static function getPointLightInfo(pointLight:PointLight, geometryPosition:Vector<Float>, light:IncidentLight) {
        var lVector:Vector<Float> = pointLight.position.subtract(geometryPosition);
        light.direction = lVector.normalize();
        var lightDistance:Float = lVector.length;
        light.color = pointLight.color;
        light.color.scale(getDistanceAttenuation(lightDistance, pointLight.distance, pointLight.decay));
        light.visible = (light.color != Vector<Float>.zeros(3));
    }
#end

#if NUM_SPOT_LIGHTS > 0
    public static var spotLights:Array<SpotLight> = [for (i in 0...NUM_SPOT_LIGHTS) new SpotLight()];

    public static function getSpotLightInfo(spotLight:SpotLight, geometryPosition:Vector<Float>, light:IncidentLight) {
        var lVector:Vector<Float> = spotLight.position.subtract(geometryPosition);
        light.direction = lVector.normalize();
        var angleCos:Float = light.direction.dotProduct(spotLight.direction);
        var spotAttenuation:Float = getSpotAttenuation(spotLight.coneCos, spotLight.penumbraCos, angleCos);
        if (spotAttenuation > 0.0) {
            var lightDistance:Float = lVector.length;
            light.color = spotLight.color.multiply(spotAttenuation);
            light.color.scale(getDistanceAttenuation(lightDistance, spotLight.distance, spotLight.decay));
            light.visible = (light.color != Vector<Float>.zeros(3));
        } else {
            light.color = Vector<Float>.zeros(3);
            light.visible = false;
        }
    }
#end

#if NUM_RECT_AREA_LIGHTS > 0
    public static var rectAreaLights:Array<RectAreaLight> = [for (i in 0...NUM_RECT_AREA_LIGHTS) new RectAreaLight()];

    public static var ltc_1:Texture;
    public static var ltc_2:Texture;
#end

#if NUM_HEMI_LIGHTS > 0
    public static var hemisphereLights:Array<HemisphereLight> = [for (i in 0...NUM_HEMI_LIGHTS) new HemisphereLight()];

    public static function getHemisphereLightIrradiance(hemiLight:HemisphereLight, normal:Vector<Float>):Vector<Float> {
        var dotNL:Float = normal.dotProduct(hemiLight.direction);
        var hemiDiffuseWeight:Float = 0.5 * dotNL + 0.5;
        var irradiance:Vector<Float> = hemiLight.groundColor.add(hemiLight.skyColor.subtract(hemiLight.groundColor).multiply(hemiDiffuseWeight));
        return irradiance;
    }
#end
}

class DirectionalLight {
    public var direction:Vector<Float>;
    public var color:Vector<Float>;
}

class PointLight {
    public var position:Vector<Float>;
    public var color:Vector<Float>;
    public var distance:Float;
    public var decay:Float;
}

class SpotLight {
    public var position:Vector<Float>;
    public var direction:Vector<Float>;
    public var color:Vector<Float>;
    public var distance:Float;
    public var decay:Float;
    public var coneCos:Float;
    public var penumbraCos:Float;
}

class RectAreaLight {
    public var color:Vector<Float>;
    public var position:Vector<Float>;
    public var halfWidth:Vector<Float>;
    public var halfHeight:Vector<Float>;
}

class HemisphereLight {
    public var direction:Vector<Float>;
    public var skyColor:Vector<Float>;
    public var groundColor:Vector<Float>;
}

class IncidentLight {
    public var color:Vector<Float>;
    public var direction:Vector<Float>;
    public var visible:Bool;
}