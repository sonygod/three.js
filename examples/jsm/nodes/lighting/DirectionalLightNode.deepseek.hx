import three.js.examples.jsm.nodes.lighting.AnalyticLightNode;
import three.js.examples.jsm.nodes.lighting.LightNode;
import three.js.examples.jsm.nodes.lighting.LightsNode;
import three.js.examples.jsm.nodes.core.Node;

import three.js.DirectionalLight;

class DirectionalLightNode extends AnalyticLightNode {

	public function new(light:Dynamic = null) {
		super(light);
	}

	public function setup(builder:Dynamic) {
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

Node.addNodeClass('DirectionalLightNode', DirectionalLightNode);

LightsNode.addLightNode(DirectionalLight, DirectionalLightNode);