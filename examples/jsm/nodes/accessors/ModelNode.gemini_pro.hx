import Object3DNode from "./Object3DNode";
import {addNodeClass} from "../core/Node";
import {nodeImmutable} from "../shadernode/ShaderNode";

class ModelNode extends Object3DNode {

	public static var DIRECTION:Int = 0;
	public static var VIEW_MATRIX:Int = 1;
	public static var NORMAL_MATRIX:Int = 2;
	public static var WORLD_MATRIX:Int = 3;
	public static var POSITION:Int = 4;
	public static var SCALE:Int = 5;
	public static var VIEW_POSITION:Int = 6;

	public function new(scope:Int = VIEW_MATRIX) {
		super(scope);
	}

	override public function update(frame:Dynamic) {
		this.object3d = frame.object;
		super.update(frame);
	}
}

export var ModelNode:Class<ModelNode> = ModelNode;

export var modelDirection = nodeImmutable(ModelNode, ModelNode.DIRECTION);
export var modelViewMatrix = nodeImmutable(ModelNode, ModelNode.VIEW_MATRIX).label("modelViewMatrix").temp("ModelViewMatrix");
export var modelNormalMatrix = nodeImmutable(ModelNode, ModelNode.NORMAL_MATRIX);
export var modelWorldMatrix = nodeImmutable(ModelNode, ModelNode.WORLD_MATRIX);
export var modelPosition = nodeImmutable(ModelNode, ModelNode.POSITION);
export var modelScale = nodeImmutable(ModelNode, ModelNode.SCALE);
export var modelViewPosition = nodeImmutable(ModelNode, ModelNode.VIEW_POSITION);

addNodeClass("ModelNode", ModelNode);