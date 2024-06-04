import AnalyticLightNode from "./AnalyticLightNode";
import LightNode from "./LightNode";
import LightsNode from "./LightsNode";
import Node from "../core/Node";
import three.DirectionalLight;

class DirectionalLightNode extends AnalyticLightNode {

	public function new(light:DirectionalLight = null) {
		super(light);
	}

	override public function setup(builder:Node.Builder) {
		super.setup(builder);

		var lightingModel = builder.context.lightingModel;

		var lightColor = this.colorNode;
		var lightDirection = LightNode.lightTargetDirection(this.light);
		var reflectedLight = builder.context.reflectedLight;

		lightingModel.direct({
			lightDirection: lightDirection,
			lightColor: lightColor,
			reflectedLight: reflectedLight,
			shadowMask: this.shadowMaskNode
		}, builder.stack, builder);
	}
}

Node.addNodeClass("DirectionalLightNode", DirectionalLightNode);
LightsNode.addLightNode(DirectionalLight, DirectionalLightNode);