import SpotLightNode from "./SpotLightNode";
import LightsNode from "./LightsNode";
import TextureNode from "../accessors/TextureNode";
import ShaderNode from "../shadernode/ShaderNode";
import Node from "../core/Node";

import IESSpotLight from "../../lights/IESSpotLight";

class IESSpotLightNode extends SpotLightNode {

  public function new() {
    super();
  }

  override function getSpotAttenuation(angleCosine:ShaderNode):ShaderNode {

    var iesMap = this.light.iesMap;

    var spotAttenuation:ShaderNode = null;

    if (iesMap != null && iesMap.isTexture) {

      var angle = angleCosine.acos().mul(1.0 / Math.PI);

      spotAttenuation = TextureNode.texture(iesMap, ShaderNode.vec2(angle, 0), 0).r;

    } else {

      spotAttenuation = super.getSpotAttenuation(angleCosine);

    }

    return spotAttenuation;

  }

}

Node.addNodeClass("IESSpotLightNode", IESSpotLightNode);
LightsNode.addLightNode(IESSpotLight, IESSpotLightNode);