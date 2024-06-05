import DFGApprox from "DFGApprox";
import ShaderNode from "../../shadernode/ShaderNode";

class EnvironmentBRDF extends ShaderNode.tslFn {
  public function new() {
    super(function(inputs: { dotNV: Dynamic, specularColor: Dynamic, specularF90: Dynamic, roughness: Dynamic }) {
      var dotNV = inputs.dotNV;
      var specularColor = inputs.specularColor;
      var specularF90 = inputs.specularF90;
      var roughness = inputs.roughness;

      var fab = DFGApprox.new( { dotNV: dotNV, roughness: roughness } );
      return specularColor.mul( fab.x ).add( specularF90.mul( fab.y ) );
    });
  }
}

export default EnvironmentBRDF;