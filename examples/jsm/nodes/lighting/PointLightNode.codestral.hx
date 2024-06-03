import AnalyticLightNode from './AnalyticLightNode';
import LightsNode.addLightNode;
import LightUtils.getDistanceAttenuation;
import UniformNode.uniform;
import Object3DNode.objectViewPosition;
import PositionNode.positionView;
import Node.addNodeClass;
import three.PointLight;

class PointLightNode extends AnalyticLightNode {

	public var cutoffDistanceNode:Dynamic;
	public var decayExponentNode:Dynamic;

	public function new(light:PointLight = null) {
		super(light);
		this.cutoffDistanceNode = uniform(0);
		this.decayExponentNode = uniform(0);
	}

	public function update(frame:Dynamic) {
		super.update(frame);
		this.cutoffDistanceNode.value = this.light.distance;
		this.decayExponentNode.value = this.light.decay;
	}

	public function setup(builder:Dynamic) {
		var lightingModel = builder.context.lightingModel;
		var lVector = objectViewPosition(this.light).sub(positionView);
		var lightDirection = lVector.normalize();
		var lightDistance = lVector.length();
		var lightAttenuation = getDistanceAttenuation({
			lightDistance: lightDistance,
			cutoffDistance: this.cutoffDistanceNode,
			decayExponent: this.decayExponentNode
		});
		var lightColor = this.colorNode.mul(lightAttenuation);
		var reflectedLight = builder.context.reflectedLight;
		lightingModel.direct({
			lightDirection: lightDirection,
			lightColor: lightColor,
			reflectedLight: reflectedLight,
			shadowMask: this.shadowMaskNode
		}, builder.stack, builder);
	}
}

addNodeClass('PointLightNode', Type.getClass<PointLightNode>());
addLightNode(Type.getClass<PointLight>(), Type.getClass<PointLightNode>());