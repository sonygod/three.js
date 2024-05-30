package three.js.examples.jsm.nodes.functions.BSDF;

import three.js.examples.jsm.nodes.DFGApprox;
import three.js.shadernode.ShaderNode;

class EnvironmentBRDF {
  public static functionshade(inputs: { dotNV: Float, specularColor: { mul: Float -> { add: Float -> Float } }, specularF90: Float, roughness: Float }): Float {
    var fab = DFGApprox.calculate({ dotNV: inputs.dotNV, roughness: inputs.roughness });
    return inputs.specularColor.mul(fab.x).add(inputs.specularF90 * fab.y);
  }
}