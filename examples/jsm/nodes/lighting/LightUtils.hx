package three.js.examples.jm.nodes.lighting;

import three.js.shadernode.ShaderNode;

class LightUtils {
  public static function getDistanceAttenuation(inputs:Dynamic):Float {
    var lightDistance:Float = inputs.lightDistance;
    var cutoffDistance:Float = inputs.cutoffDistance;
    var decayExponent:Float = inputs.decayExponent;

    // based upon Frostbite 3 Moving to Physically-based Rendering
    // page 32, equation 26: E[window1]
    // https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
    var distanceFalloff:Float = Math.pow(lightDistance, decayExponent);
    distanceFalloff = Math.max(distanceFalloff, 0.01);
    distanceFalloff = 1 / distanceFalloff;

    if (cutoffDistance > 0) {
      var attenuation:Float = distanceFalloff * Math.pow(1 - Math.pow(lightDistance / cutoffDistance, 4), 2);
      return attenuation;
    } else {
      return distanceFalloff;
    }
  }
}