import AnalyticLightNode from "./AnalyticLightNode";
import LightsNode from "./LightsNode";
import UniformNode from "../core/UniformNode";
import MathNode from "../math/MathNode";
import NormalNode from "../accessors/NormalNode";
import Object3DNode from "../accessors/Object3DNode";
import Node from "../core/Node";

import {Color, HemisphereLight} from "three";

class HemisphereLightNode extends AnalyticLightNode {

	public lightPositionNode: Object3DNode;
	public lightDirectionNode: Object3DNode;
	public groundColorNode: UniformNode<Color>;

	public function new(light: HemisphereLight = null) {
		super(light);

		this.lightPositionNode = Object3DNode.objectPosition(light);
		this.lightDirectionNode = this.lightPositionNode.normalize();

		this.groundColorNode = UniformNode.uniform(new Color());
	}

	public function update(frame: Dynamic): Void {
		super.update(frame);
		this.lightPositionNode.object3d = this.light;
		this.groundColorNode.value.copy(this.light.groundColor).multiplyScalar(this.light.intensity);
	}

	public function setup(builder: Dynamic): Void {
		var dotNL = NormalNode.normalView.dot(this.lightDirectionNode);
		var hemiDiffuseWeight = dotNL.mul(0.5).add(0.5);

		var irradiance = MathNode.mix(this.groundColorNode, this.colorNode, hemiDiffuseWeight);

		builder.context.irradiance.addAssign(irradiance);
	}

}

export default HemisphereLightNode;

Node.addNodeClass('HemisphereLightNode', HemisphereLightNode);
LightsNode.addLightNode(HemisphereLight, HemisphereLightNode);