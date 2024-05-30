import AnalyticLightNode.hx;
import LightsNode.hx;
import LightUtils.hx;
import UniformNode.hx;
import Object3DNode.hx;
import PositionNode.hx;
import Node.hx;

import three.PointLight;

class PointLightNode extends AnalyticLightNode {

	public var cutoffDistanceNode:UniformNode;
	public var decayExponentNode:UniformNode;

	public function new(light:Null<PointLight> = null) {

		super(light);

		this.cutoffDistanceNode = new UniformNode(0);
		this.decayExponentNode = new UniformNode(0);

	}

	public function update(frame:Dynamic) {

		var light = this.light;

		super.update(frame);

		this.cutoffDistanceNode.value = light.distance;
		this.decayExponentNode.value = light.decay;

	}

	public function setup(builder:Dynamic) {

		var colorNode = this.colorNode;
		var cutoffDistanceNode = this.cutoffDistanceNode;
		var decayExponentNode = this.decayExponentNode;
		var light = this.light;

		var lightingModel = builder.context.lightingModel;

		var lVector = objectViewPosition(light).sub(positionView); // @TODO: Add it into LightNode

		var lightDirection = lVector.normalize();
		var lightDistance = lVector.length();

		var lightAttenuation = getDistanceAttenuation({
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

Node.addNodeClass('PointLightNode', PointLightNode);

LightsNode.addLightNode(PointLight, PointLightNode);