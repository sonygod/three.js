import AnalyticLightNode from "./AnalyticLightNode";
import LightsNode from "./LightsNode";
import Node from "../core/Node";
import three.lights.AmbientLight;

class AmbientLightNode extends AnalyticLightNode {

  public function new(light:AmbientLight = null) {
    super(light);
  }

  override public function setup(context:Dynamic) {
    context.irradiance.addAssign(this.colorNode);
  }

}

Node.addNodeClass("AmbientLightNode", AmbientLightNode);
LightsNode.addLightNode(AmbientLight, AmbientLightNode);