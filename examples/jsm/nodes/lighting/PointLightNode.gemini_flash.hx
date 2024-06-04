import AnalyticLightNode from "./AnalyticLightNode";
import LightsNode from "./LightsNode";
import LightUtils from "./LightUtils";
import UniformNode from "../core/UniformNode";
import Object3DNode from "../accessors/Object3DNode";
import PositionNode from "../accessors/PositionNode";
import Node from "../core/Node";
import three.PointLight;

class PointLightNode extends AnalyticLightNode {

	public var cutoffDistanceNode:UniformNode<Float>;
	public var decayExponentNode:UniformNode<Float>;

	public function new(light:PointLight = null) {
		super(light);

		this.cutoffDistanceNode = new UniformNode(0.0);
		this.decayExponentNode = new UniformNode(0.0);
	}

	override public function update(frame:Dynamic) {
		super.update(frame);

		this.cutoffDistanceNode.value = this.light.distance;
		this.decayExponentNode.value = this.light.decay;
	}

	override public function setup(builder:Dynamic) {
		var colorNode = this.colorNode;
		var cutoffDistanceNode = this.cutoffDistanceNode;
		var decayExponentNode = this.decayExponentNode;
		var light = this.light;
		var lightingModel = builder.context.lightingModel;

		var lVector = Object3DNode.objectViewPosition(light).sub(PositionNode.positionView);
		// @TODO: Add it into LightNode

		var lightDirection = lVector.normalize();
		var lightDistance = lVector.length();

		var lightAttenuation = LightUtils.getDistanceAttenuation({
			lightDistance: lightDistance,
			cutoffDistance: cutoffDistanceNode,
			decayExponent: decayExponentNode
		});

		var lightColor = colorNode.mul(lightAttenuation);

		var reflectedLight = builder.context.reflectedLight;

		lightingModel.direct({
			lightDirection: lightDirection,
			lightColor: lightColor,
			reflectedLight: reflectedLight,
			shadowMask: this.shadowMaskNode
		}, builder.stack, builder);
	}
}

export default PointLightNode;

Node.addNodeClass("PointLightNode", PointLightNode);

LightsNode.addLightNode(PointLight, PointLightNode);