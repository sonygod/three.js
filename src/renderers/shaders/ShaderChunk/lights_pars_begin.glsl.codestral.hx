class LightsParsBegin {
    public var receiveShadow: Bool;
    public var ambientLightColor: Float3;

    #if defined(USE_LIGHT_PROBES)
    public var lightProbe: Array<Float3>;
    #end

    public function new() {
        this.lightProbe = new Array<Float3>(9);
    }

    public function shGetIrradianceAt(normal: Float3, shCoefficients: Array<Float3>): Float3 {
        var x = normal.x, y = normal.y, z = normal.z;
        var result = shCoefficients[0] * 0.886227;

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

    public function getLightProbeIrradiance(lightProbe: Array<Float3>, normal: Float3): Float3 {
        var worldNormal = inverseTransformDirection(normal, viewMatrix);
        var irradiance = shGetIrradianceAt(worldNormal, lightProbe);
        return irradiance;
    }

    public function getAmbientLightIrradiance(ambientLightColor: Float3): Float3 {
        var irradiance = ambientLightColor;
        return irradiance;
    }

    public function getDistanceAttenuation(lightDistance: Float, cutoffDistance: Float, decayExponent: Float): Float {
        #if defined(LEGACY_LIGHTS)
        if (cutoffDistance > 0.0 && decayExponent > 0.0) {
            return Math.pow(Math.max(Math.min(-lightDistance / cutoffDistance + 1.0, 1.0), 0.0), decayExponent);
        }
        return 1.0;
        #else
        var distanceFalloff = 1.0 / Math.max(Math.pow(lightDistance, decayExponent), 0.01);
        if (cutoffDistance > 0.0) {
            distanceFalloff *= Math.pow(Math.max(1.0 - Math.pow(lightDistance / cutoffDistance, 4), 0.0), 2);
        }
        return distanceFalloff;
        #end
    }

    public function getSpotAttenuation(coneCosine: Float, penumbraCosine: Float, angleCosine: Float): Float {
        return smoothstep(coneCosine, penumbraCosine, angleCosine);
    }

    #if NUM_DIR_LIGHTS > 0
    public var directionalLights: Array<DirectionalLight>;

    public function new() {
        this.directionalLights = new Array<DirectionalLight>(NUM_DIR_LIGHTS);
    }

    public function getDirectionalLightInfo(directionalLight: DirectionalLight, out light: IncidentLight) {
        light.color = directionalLight.color;
        light.direction = directionalLight.direction;
        light.visible = true;
    }
    #end

    // Continue this pattern for other light types and functions.
    // Remember that Haxe doesn't support template functions, so you'll need to write out each light type separately.
    // Also, note that Haxe doesn't have the same exact functions as GLSL, so you'll need to use the equivalent Haxe functions.
}