import Node from "../core/Node";
import CameraNode from "./CameraNode";
import NormalNode from "./NormalNode";
import PositionNode from "./PositionNode";
import ShaderNode from "../shadernode/ShaderNode";

class ReflectVectorNode extends Node {

	public function new() {
		super("vec3");
	}

	override public function getHash(builder:Dynamic):String {
		return "reflectVector";
	}

	override public function setup():Dynamic {
		var reflectView = positionViewDirection.negate().reflect(transformedNormalView);
		return reflectView.transformDirection(CameraNode.cameraViewMatrix);
	}

}

var reflectVector = ShaderNode.nodeImmutable(ReflectVectorNode);

Node.addNodeClass("ReflectVectorNode", ReflectVectorNode);