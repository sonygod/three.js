import AnalyticLightNode from "./AnalyticLightNode";
import LightsNode from "./LightsNode";
import UniformNode from "../core/UniformNode";
import MathNode from "../math/MathNode";
import NormalNode from "../accessors/NormalNode";
import Object3DNode from "../accessors/Object3DNode";
import Node from "../core/Node";

import {Color, HemisphereLight} from "three";

class HemisphereLightNode extends AnalyticLightNode {

  public var lightPositionNode: Object3DNode;
  public var lightDirectionNode: MathNode;
  public var groundColorNode: UniformNode<Color>;

  public function new(light: HemisphereLight = null) {
    super(light);

    lightPositionNode = Object3DNode.objectPosition(light);
    lightDirectionNode = lightPositionNode.normalize();

    groundColorNode = UniformNode.uniform(new Color());
  }

  override public function update(frame: Int) {
    super.update(frame);

    lightPositionNode.object3d = light;
    groundColorNode.value = light.groundColor.clone().multiplyScalar(light.intensity);
  }

  override public function setup(builder: Node.Builder) {
    var dotNL = NormalNode.normalView.dot(lightDirectionNode);
    var hemiDiffuseWeight = dotNL.mul(0.5).add(0.5);
    var irradiance = MathNode.mix(groundColorNode, colorNode, hemiDiffuseWeight);

    builder.context.irradiance.addAssign(irradiance);
  }
}

export default HemisphereLightNode;

Node.addNodeClass("HemisphereLightNode", HemisphereLightNode);
LightsNode.addLightNode(HemisphereLight, HemisphereLightNode);