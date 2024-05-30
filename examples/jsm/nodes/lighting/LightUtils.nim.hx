import three.shadernode.ShaderNode;

class LightUtils {
    public static function getDistanceAttenuation(inputs: Dynamic): ShaderNode {
        var lightDistance = inputs.lightDistance;
        var cutoffDistance = inputs.cutoffDistance;
        var decayExponent = inputs.decayExponent;

        // based upon Frostbite 3 Moving to Physically-based Rendering
        // page 32, equation 26: E[window1]
        // https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
        var distanceFalloff = lightDistance.pow(decayExponent).max(0.01).reciprocal();

        return cutoffDistance.greaterThan(0).cond(
            distanceFalloff.mul(lightDistance.div(cutoffDistance).pow4().oneMinus().clamp().pow2()),
            distanceFalloff
        );
    }
}