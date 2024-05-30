import three.AnalyticLightNode;
import three.LightsNode.addLightNode;
import three.LightUtils.getDistanceAttenuation;
import three.UniformNode.uniform;
import three.Object3DNode.objectViewPosition;
import three.PositionNode.positionView;
import three.Node.addNodeClass;

import three.PointLight;

class PointLightNode extends AnalyticLightNode {

	public function new(light:PointLight = null) {

		super(light);

		this.cutoffDistanceNode = uniform(0);
		this.decayExponentNode = uniform(0);

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
			lightDistance:lightDistance,
			cutoffDistance:cutoffDistanceNode,
			decayExponent:decayExponentNode
		});

		var lightColor = colorNode.mul(lightAttenuation);

		var reflectedLight = builder.context.reflectedLight;

		lightingModel.direct({
			lightDirection:lightDirection,
			lightColor:lightColor,
			reflectedLight:reflectedLight,
			shadowMask:this.shadowMaskNode
		}, builder.stack, builder);

	}

}

addNodeClass('PointLightNode', PointLightNode);

addLightNode(PointLight, PointLightNode);