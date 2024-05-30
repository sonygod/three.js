import AnalyticLightNode from AnalyticLightNode.hx;
import LightsNode from LightsNode.hx;
import UniformNode from UniformNode.hx;
import MathNode from MathNode.hx;
import NormalNode from NormalNode.hx;
import Object3DNode from Object3DNode.hx;
import Node from Node.hx;

import Color from Color.hx;
import HemisphereLight from HemisphereLight.hx;

class HemisphereLightNode extends AnalyticLightNode {
	public var lightPositionNode:Object3DNode;
	public var lightDirectionNode:UniformNode;
	public var groundColorNode:UniformNode;

	public function new(light:HemisphereLight = null) {
		super(light);
		this.lightPositionNode = Object3DNode.objectPosition(light);
		this.lightDirectionNode = this.lightPositionNode.normalize();
		this.groundColorNode = UniformNode.uniform(Color.new());
	}

	public function update(frame:Int) {
		super.update(frame);
		this.lightPositionNode.object3d = cast light;
		this.groundColorNode.value.copy(light.groundColor).multiplyScalar(light.intensity);
	}

	public function setup(builder:Builder) {
		var colorNode = cast this.colorNode;
		var groundColorNode = cast this.groundColorNode;
		var lightDirectionNode = cast this.lightDirectionNode;
		var dotNL = NormalNode.normalView.dot(lightDirectionNode);
		var hemiDiffuseWeight = MathNode.mul(dotNL, 0.5).add(0.5);
		var irradiance = MathNode.mix(groundColorNode, colorNode, hemiDiffuseWeight);
		builder.context.irradiance.addAssign(irradiance);
	}
}

@:export
class HemisphereLightNodeExt {
	public static function __init__() {
		Node.addNodeClass('HemisphereLightNode', HemisphereLightNode);
		LightsNode.addLightNode(HemisphereLight, HemisphereLightNode);
	}
}