import three.js.examples.jsm.nodes.lighting.ShaderNode;

class LightUtils {
    public static function getDistanceAttenuation(inputs:Dynamic):Dynamic {
        var lightDistance = inputs.lightDistance;
        var cutoffDistance = inputs.cutoffDistance;
        var decayExponent = inputs.decayExponent;

        var distanceFalloff = lightDistance.pow(decayExponent).max(0.01).reciprocal();

        return cutoffDistance.greaterThan(0).cond(
            distanceFalloff.mul(lightDistance.div(cutoffDistance).pow4().oneMinus().clamp().pow2()),
            distanceFalloff
        );
    }
}