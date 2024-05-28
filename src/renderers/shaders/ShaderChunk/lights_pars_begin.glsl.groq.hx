package three.js.src.renderers.shaders.ShaderChunk;

import openfl.gl.GLShader;

class LightsParsBegin {
    // uniform bool receiveShadow;
    public static var receiveShadow:Bool;

    // uniform vec3 ambientLightColor;
    public static var ambientLightColor:Vec3;

    #if defined( USE_LIGHT_PROBES )
    // uniform vec3 lightProbe[ 9 ];
    public static var lightProbe:Array<Vec3> = [for (i in 0...9) Vec3.create(0, 0, 0)];
    #end

    // get the irradiance (radiance convolved with cosine lobe) at the point 'normal' on the unit sphere
    // source: https://graphics.stanford.edu/papers/envmap/envmap.pdf
    public static function shGetIrradianceAt(normal:Vec3, shCoefficients:Array<Vec3>):Vec3 {
        // normal is assumed to have unit length
        var x:Float = normal.x;
        var y:Float = normal.y;
        var z:Float = normal.z;

        // band 0
        var result:Vec3 = shCoefficients[0].multiply(0.886227);

        // band 1
        result.add(shCoefficients[1].multiply(2.0 * 0.511664 * y));
        result.add(shCoefficients[2].multiply(2.0 * 0.511664 * z));
        result.add(shCoefficients[3].multiply(2.0 * 0.511664 * x));

        // band 2
        result.add(shCoefficients[4].multiply(2.0 * 0.429043 * x * y));
        result.add(shCoefficients[5].multiply(2.0 * 0.429043 * y * z));
        result.add(shCoefficients[6].multiply(0.743125 * z * z - 0.247708));
        result.add(shCoefficients[7].multiply(2.0 * 0.429043 * x * z));
        result.add(shCoefficients[8].multiply(0.429043 * (x * x - y * y)));

        return result;
    }

    public static function getLightProbeIrradiance(lightProbe:Array<Vec3>, normal:Vec3):Vec3 {
        var worldNormal:Vec3 = inverseTransformDirection(normal, viewMatrix);

        var irradiance:Vec3 = shGetIrradianceAt(worldNormal, lightProbe);

        return irradiance;
    }

    public static function getAmbientLightIrradiance(ambientLightColor:Vec3):Vec3 {
        var irradiance:Vec3 = ambientLightColor;

        return irradiance;
    }

    public static function getDistanceAttenuation(lightDistance:Float, cutoffDistance:Float, decayExponent:Float):Float {
        #if defined ( LEGACY_LIGHTS )
        if (cutoffDistance > 0.0 && decayExponent > 0.0) {
            return Math.pow(Math.max(0.0, 1.0 - lightDistance / cutoffDistance), decayExponent);
        }
        return 1.0;
        #else
        var distanceFalloff:Float = 1.0 / Math.max(Math.pow(lightDistance, decayExponent), 0.01);

        if (cutoffDistance > 0.0) {
            distanceFalloff *= Math.pow(Math.max(0.0, 1.0 - Math.pow4(lightDistance / cutoffDistance)), 2);
        }

        return distanceFalloff;
        #end
    }

    public static function getSpotAttenuation(coneCosine:Float, penumbraCosine:Float, angleCosine:Float):Float {
        return smoothstep(coneCosine, penumbraCosine, angleCosine);
    }

    #if NUM_DIR_LIGHTS > 0
    public static class DirectionalLight {
        public var direction:Vec3;
        public var color:Vec3;
    }

    public static var directionalLights:Array<DirectionalLight> = [for (i in 0...NUM_DIR_LIGHTS) new DirectionalLight()];

    public static function getDirectionalLightInfo(directionalLight:DirectionalLight, light:IncidentLight) {
        light.color = directionalLight.color;
        light.direction = directionalLight.direction;
        light.visible = true;
    }
    #end

    #if NUM_POINT_LIGHTS > 0
    public static class PointLight {
        public var position:Vec3;
        public var color:Vec3;
        public var distance:Float;
        public var decay:Float;
    }

    public static var pointLights:Array<PointLight> = [for (i in 0...NUM_POINT_LIGHTS) new PointLight()];

    public static function getPointLightInfo(pointLight:PointLight, geometryPosition:Vec3, light:IncidentLight) {
        var lVector:Vec3 = pointLight.position.subtract(geometryPosition);

        light.direction = lVector.normalize();

        var lightDistance:Float = lVector.length;

        light.color = pointLight.color;
        light.color.multiply(getDistanceAttenuation(lightDistance, pointLight.distance, pointLight.decay));
        light.visible = (light.color != Vec3.create(0, 0, 0));
    }
    #end

    #if NUM_SPOT_LIGHTS > 0
    public static class SpotLight {
        public var position:Vec3;
        public var direction:Vec3;
        public var color:Vec3;
        public var distance:Float;
        public var decay:Float;
        public var coneCos:Float;
        public var penumbraCos:Float;
    }

    public static var spotLights:Array<SpotLight> = [for (i in 0...NUM_SPOT_LIGHTS) new SpotLight()];

    public static function getSpotLightInfo(spotLight:SpotLight, geometryPosition:Vec3, light:IncidentLight) {
        var lVector:Vec3 = spotLight.position.subtract(geometryPosition);

        light.direction = lVector.normalize();

        var angleCos:Float = Vec3.dot(light.direction, spotLight.direction);

        var spotAttenuation:Float = getSpotAttenuation(spotLight.coneCos, spotLight.penumbraCos, angleCos);

        if (spotAttenuation > 0.0) {
            var lightDistance:Float = lVector.length;

            light.color = spotLight.color.multiply(spotAttenuation);
            light.color.multiply(getDistanceAttenuation(lightDistance, spotLight.distance, spotLight.decay));
            light.visible = (light.color != Vec3.create(0, 0, 0));
        } else {
            light.color = Vec3.create(0, 0, 0);
            light.visible = false;
        }
    }
    #end

    #if NUM_RECT_AREA_LIGHTS > 0
    public static class RectAreaLight {
        public var color:Vec3;
        public var position:Vec3;
        public var halfWidth:Vec3;
        public var halfHeight:Vec3;
    }

    // Pre-computed values of LinearTransformedCosine approximation of BRDF
    // BRDF approximation Texture is 64x64
    public static var ltc_1:GLShader;
    public static var ltc_2:GLShader;

    public static var rectAreaLights:Array<RectAreaLight> = [for (i in 0...NUM_RECT_AREA_LIGHTS) new RectAreaLight()];
    #end

    #if NUM_HEMI_LIGHTS > 0
    public static class HemisphereLight {
        public var direction:Vec3;
        public var skyColor:Vec3;
        public var groundColor:Vec3;
    }

    public static var hemisphereLights:Array<HemisphereLight> = [for (i in 0...NUM_HEMI_LIGHTS) new HemisphereLight()];

    public static function getHemisphereLightIrradiance(hemiLight:HemisphereLight, normal:Vec3):Vec3 {
        var dotNL:Float = Vec3.dot(normal, hemiLight.direction);
        var hemiDiffuseWeight:Float = 0.5 * dotNL + 0.5;

        var irradiance:Vec3 = Vec3.mix(hemiLight.groundColor, hemiLight.skyColor, hemiDiffuseWeight);

        return irradiance;
    }
    #end
}