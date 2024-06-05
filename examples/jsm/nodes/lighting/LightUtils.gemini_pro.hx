import shadernode.ShaderNode;

class GetDistanceAttenuation extends ShaderNode {
  static function get(inputs: {lightDistance:ShaderNode, cutoffDistance:ShaderNode, decayExponent:ShaderNode}):ShaderNode {
    // based upon Frostbite 3 Moving to Physically-based Rendering
    // page 32, equation 26: E[window1]
    // https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
    var distanceFalloff = inputs.lightDistance.pow(inputs.decayExponent).max(0.01).reciprocal();
    return inputs.cutoffDistance.greaterThan(0).cond(
      distanceFalloff.mul(inputs.lightDistance.div(inputs.cutoffDistance).pow(4).oneMinus().clamp().pow(2)),
      distanceFalloff
    );
  }
}