import DFGApprox from "DFGApprox";
import ShaderNode from "../../shadernode/ShaderNode";

class EnvironmentBRDF extends ShaderNode.TSLFn {
  public function new() {
    super(function(inputs) {
      var dotNV = inputs.dotNV;
      var specularColor = inputs.specularColor;
      var specularF90 = inputs.specularF90;
      var roughness = inputs.roughness;

      var fab = DFGApprox.compute(dotNV, roughness);
      return specularColor.mul(fab.x).add(specularF90.mul(fab.y));
    });
  }
}

export default EnvironmentBRDF;