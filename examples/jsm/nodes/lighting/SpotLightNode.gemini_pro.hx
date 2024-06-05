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
  public coneCosNode:UniformNode<Float>;
  public penumbraCosNode:UniformNode<Float>;
  public cutoffDistanceNode:UniformNode<Float>;
  public decayExponentNode:UniformNode<Float>;

  public function new(light:SpotLight = null) {
    super(light);

    this.coneCosNode = new UniformNode(0.0);
    this.penumbraCosNode = new UniformNode(0.0);
    this.cutoffDistanceNode = new UniformNode(0.0);
    this.decayExponentNode = new UniformNode(0.0);
  }

  override public function update(frame:Int) {
    super.update(frame);

    this.coneCosNode.value = Math.cos(this.light.angle);
    this.penumbraCosNode.value = Math.cos(this.light.angle * (1 - this.light.penumbra));

    this.cutoffDistanceNode.value = this.light.distance;
    this.decayExponentNode.value = this.light.decay;
  }

  public function getSpotAttenuation(angleCosine:Float):Float {
    return MathNode.smoothstep(this.coneCosNode, this.penumbraCosNode, angleCosine);
  }

  override public function setup(builder:Node.Builder):Void {
    super.setup(builder);

    var lightingModel = builder.context.lightingModel;

    var lightDirection = Object3DNode.objectViewPosition(this.light)
      .sub(PositionNode.positionView)
      .normalize();
    var angleCos = lightDirection.dot(LightNode.lightTargetDirection(this.light));
    var spotAttenuation = this.getSpotAttenuation(angleCos);

    var lightDistance = lightDirection.length();
    var lightAttenuation = LightUtils.getDistanceAttenuation({
      lightDistance: lightDistance,
      cutoffDistance: this.cutoffDistanceNode,
      decayExponent: this.decayExponentNode
    });

    var lightColor = this.colorNode.mul(spotAttenuation).mul(lightAttenuation);

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