package three.js.examples.jsm.nodes.lighting;

import three.js.shadernode.ShaderNode;

class LightUtils {
    public static function getDistanceAttenuation(inputs: { lightDistance: Float, cutoffDistance: Float, decayExponent: Float }): Float {
        var lightDistance = inputs.lightDistance;
        var cutoffDistance = inputs.cutoffDistance;
        var decayExponent = inputs.decayExponent;

        var distanceFalloff = Math.pow(lightDistance, decayExponent);
        distanceFalloff = Math.max(distanceFalloff, 0.01);
        distanceFalloff = 1.0 / distanceFalloff;

        if (cutoffDistance > 0) {
            var falloff = distanceFalloff * Math.pow(1 - Math.pow(lightDistance / cutoffDistance, 4), 2);
            return falloff;
        } else {
            return distanceFalloff;
        }
    }
}