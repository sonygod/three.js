import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";
import Object3DNode from "../accessors/Object3DNode";
import CameraNode from "../accessors/CameraNode";

class LightNode extends Node {

	public static TARGET_DIRECTION:String = "targetDirection";

	public scope:String;
	public light:Dynamic;

	public function new(scope:String = LightNode.TARGET_DIRECTION, light:Dynamic = null) {
		super();
		this.scope = scope;
		this.light = light;
	}

	public function setup():Dynamic {
		var { scope, light } = this;

		var output:Dynamic = null;

		if (scope == LightNode.TARGET_DIRECTION) {
			output = CameraNode.cameraViewMatrix.transformDirection(
				Object3DNode.objectPosition(light).sub(Object3DNode.objectPosition(light.target))
			);
		}

		return output;
	}

	public function serialize(data:Dynamic):Void {
		super.serialize(data);
		data.scope = this.scope;
	}

	public function deserialize(data:Dynamic):Void {
		super.deserialize(data);
		this.scope = data.scope;
	}

}

export var lightTargetDirection = ShaderNode.nodeProxy(LightNode, LightNode.TARGET_DIRECTION);

Node.addNodeClass("LightNode", LightNode);

export default LightNode;