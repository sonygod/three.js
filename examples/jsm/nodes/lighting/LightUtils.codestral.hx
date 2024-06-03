import js.Browser.Math;
import js.Browser.Window;

class LightUtils {

    public static function getDistanceAttenuation(inputs:Dynamic):Float {
        var lightDistance:Float = inputs.lightDistance;
        var cutoffDistance:Float = inputs.cutoffDistance;
        var decayExponent:Float = inputs.decayExponent;

        var distanceFalloff:Float = Math.max(Math.pow(lightDistance, decayExponent), 0.01);
        distanceFalloff = 1.0 / distanceFalloff;

        if (cutoffDistance > 0) {
            return distanceFalloff * Math.pow(1.0 - Math.pow(lightDistance / cutoffDistance, 4), 2);
        } else {
            return distanceFalloff;
        }
    }
}