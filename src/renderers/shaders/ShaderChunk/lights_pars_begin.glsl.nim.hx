package three.js.src.renderers.shaders.ShaderChunk;

import three.js.src.renderers.shaders.ShaderChunk.lights_pars_begin.IncidentLight;

class lights_pars_begin {
    public static var receiveShadow:Bool;
    public static var ambientLightColor:three.js.src.math.Color;

    #if defined( USE_LIGHT_PROBES )
        public static var lightProbe:Array<three.js.src.math.Vector3>;
    #end

    public static function shGetIrradianceAt(normal:three.js.src.math.Vector3, shCoefficients:Array<three.js.src.math.Vector3>):three.js.src.math.Vector3 {
        var x:Float = normal.x, y:Float = normal.y, z:Float = normal.z;
        var result:three.js.src.math.Vector3 = shCoefficients[0] * 0.886227;
        result += shCoefficients[1] * 2.0 * 0.511664 * y;
        result += shCoefficients[2] * 2.0 * 0.511664 * z;
        result += shCoefficients[3] * 2.0 * 0.511664 * x;
        result += shCoefficients[4] * 2.0 * 0.429043 * x * y;
        result += shCoefficients[5] * 2.0 * 0.429043 * y * z;
        result += shCoefficients[6] * (0.743125 * z * z - 0.247708);
        result += shCoefficients[7] * 2.0 * 0.429043 * x * z;
        result += shCoefficients[8] * 0.429043 * (x * x - y * y);
        return result;
    }

    public static function getLightProbeIrradiance(lightProbe:Array<three.js.src.math.Vector3>, normal:three.js.src.math.Vector3):three.js.src.math.Vector3 {
        var worldNormal:three.js.src.math.Vector3 = three.js.src.math.Vector3.transformDirection(normal, three.js.src.math.Matrix4.inverse(three.js.src.cameras.Camera.viewMatrix));
        var irradiance:three.js.src.math.Vector3 = shGetIrradianceAt(worldNormal, lightProbe);
        return irradiance;
    }

    public static function getAmbientLightIrradiance(ambientLightColor:three.js.src.math.Vector3):three.js.src.math.Vector3 {
        var irradiance:three.js.src.math.Vector3 = ambientLightColor;
        return irradiance;
    }

    public static function getDistanceAttenuation(lightDistance:Float, cutoffDistance:Float, decayExponent:Float):Float {
        #if defined ( LEGACY_LIGHTS )
            if (cutoffDistance > 0.0 && decayExponent > 0.0) {
                return Math.pow(Math.max(0.0, -lightDistance / cutoffDistance + 1.0), decayExponent);
            }
            return 1.0;
        #else
            var distanceFalloff:Float = 1.0 / Math.max(Math.pow(lightDistance, decayExponent), 0.01);
            if (cutoffDistance > 0.0) {
                distanceFalloff *= Math.pow(Math.max(0.0, 1.0 - Math.pow(lightDistance / cutoffDistance, 4)), 2);
            }
            return distanceFalloff;
        #end
    }

    public static function getSpotAttenuation(coneCosine:Float, penumbraCosine:Float, angleCosine:Float):Float {
        return Math.smoothstep(coneCosine, penumbraCosine, angleCosine);
    }

    #if NUM_DIR_LIGHTS > 0
        public static var directionalLights:Array<three.js.src.lights.DirectionalLight>;

        public static function getDirectionalLightInfo(directionalLight:three.js.src.lights.DirectionalLight, light:IncidentLight):Void {
            light.color = directionalLight.color;
            light.direction = directionalLight.direction;
            light.visible = true;
        }
    #end

    #if NUM_POINT_LIGHTS > 0
        public static var pointLights:Array<three.js.src.lights.PointLight>;

        public static function getPointLightInfo(pointLight:three.js.src.lights.PointLight, geometryPosition:three.js.src.math.Vector3, light:IncidentLight):Void {
            var lVector:three.js.src.math.Vector3 = pointLight.position.clone().sub(geometryPosition);
            light.direction = lVector.normalize();
            var lightDistance:Float = lVector.length();
            light.color = pointLight.color;
            light.color *= getDistanceAttenuation(lightDistance, pointLight.distance, pointLight.decay);
            light.visible = (light.color != three.js.src.math.Vector3.ZERO);
        }
    #end

    #if NUM_SPOT_LIGHTS > 0
        public static var spotLights:Array<three.js.src.lights.SpotLight>;

        public static function getSpotLightInfo(spotLight:three.js.src.lights.SpotLight, geometryPosition:three.js.src.math.Vector3, light:IncidentLight):Void {
            var lVector:three.js.src.math.Vector3 = spotLight.position.clone().sub(geometryPosition);
            light.direction = lVector.normalize();
            var angleCos:Float = light.direction.dot(spotLight.direction);
            var spotAttenuation:Float = getSpotAttenuation(spotLight.coneCos, spotLight.penumbraCos, angleCos);
            if (spotAttenuation > 0.0) {
                var lightDistance:Float = lVector.length();
                light.color = spotLight.color * spotAttenuation;
                light.color *= getDistanceAttenuation(lightDistance, spotLight.distance, spotLight.decay);
                light.visible = (light.color != three.js.src.math.Vector3.ZERO);
            } else {
                light.color = three.js.src.math.Vector3.ZERO;
                light.visible = false;
            }
        }
    #end

    #if NUM_RECT_AREA_LIGHTS > 0
        public static var rectAreaLights:Array<three.js.src.lights.RectAreaLight>;
        public static var ltc_1:three.js.src.textures.Texture;
        public static var ltc_2:three.js.src.textures.Texture;
    #end

    #if NUM_HEMI_LIGHTS > 0
        public static var hemisphereLights:Array<three.js.src.lights.HemisphereLight>;

        public static function getHemisphereLightIrradiance(hemiLight:three.js.src.lights.HemisphereLight, normal:three.js.src.math.Vector3):three.js.src.math.Vector3 {
            var dotNL:Float = normal.dot(hemiLight.direction);
            var hemiDiffuseWeight:Float = 0.5 * dotNL + 0.5;
            var irradiance:three.js.src.math.Vector3 = three.js.src.math.Vector3.lerp(hemiLight.groundColor, hemiLight.skyColor, hemiDiffuseWeight);
            return irradiance;
        }
    #end
}