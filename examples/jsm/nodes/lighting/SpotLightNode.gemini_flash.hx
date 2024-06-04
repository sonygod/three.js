import AnalyticLightNode from "./AnalyticLightNode";
import LightNode from "./LightNode";
import LightsNode from "./LightsNode";
import LightUtils from "./LightUtils";
import UniformNode from "../core/UniformNode";
import MathNode from "../math/MathNode";
import Object3DNode from "../accessors/Object3DNode";
import PositionNode from "../accessors/PositionNode";
import Node from "../core/Node";
import SpotLight from "three";

class SpotLightNode extends AnalyticLightNode {
  public coneCosNode: UniformNode<Float>;
  public penumbraCosNode: UniformNode<Float>;
  public cutoffDistanceNode: UniformNode<Float>;
  public decayExponentNode: UniformNode<Float>;

  public function new(light: SpotLight = null) {
    super(light);
    this.coneCosNode = new UniformNode(0.);
    this.penumbraCosNode = new UniformNode(0.);
    this.cutoffDistanceNode = new UniformNode(0.);
    this.decayExponentNode = new UniformNode(0.);
  }

  override public function update(frame: Int): Void {
    super.update(frame);
    var { light } = this;
    this.coneCosNode.value = Math.cos(light.angle);
    this.penumbraCosNode.value = Math.cos(light.angle * (1 - light.penumbra));
    this.cutoffDistanceNode.value = light.distance;
    this.decayExponentNode.value = light.decay;
  }

  public function getSpotAttenuation(angleCosine: Float): Float {
    var { coneCosNode, penumbraCosNode } = this;
    return MathNode.smoothstep(coneCosNode, penumbraCosNode, angleCosine);
  }

  override public function setup(builder: Node.Builder): Void {
    super.setup(builder);
    var lightingModel = builder.context.lightingModel;
    var { colorNode, cutoffDistanceNode, decayExponentNode, light } = this;
    var lVector = Object3DNode.objectViewPosition(light).sub(PositionNode.positionView); // @TODO: Add it into LightNode
    var lightDirection = lVector.normalize();
    var angleCos = lightDirection.dot(LightNode.lightTargetDirection(light));
    var spotAttenuation = this.getSpotAttenuation(angleCos);
    var lightDistance = lVector.length();
    var lightAttenuation = LightUtils.getDistanceAttenuation({
      lightDistance: lightDistance,
      cutoffDistance: cutoffDistanceNode,
      decayExponent: decayExponentNode
    });
    var lightColor = colorNode.mul(spotAttenuation).mul(lightAttenuation);
    var reflectedLight = builder.context.reflectedLight;
    lightingModel.direct({
      lightDirection: lightDirection,
      lightColor: lightColor,
      reflectedLight: reflectedLight,
      shadowMask: this.shadowMaskNode
    }, builder.stack, builder);
  }
}

export default SpotLightNode;

Node.addNodeClass("SpotLightNode", SpotLightNode);
LightsNode.addLightNode(SpotLight, SpotLightNode);