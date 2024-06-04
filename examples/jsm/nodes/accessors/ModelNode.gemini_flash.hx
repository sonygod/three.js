import Object3DNode from "./Object3DNode";
import {addNodeClass} from "../core/Node";
import {nodeImmutable} from "../shadernode/ShaderNode";

class ModelNode extends Object3DNode {
	public static DIRECTION: Int = 0;
	public static VIEW_MATRIX: Int = 1;
	public static NORMAL_MATRIX: Int = 2;
	public static WORLD_MATRIX: Int = 3;
	public static POSITION: Int = 4;
	public static SCALE: Int = 5;
	public static VIEW_POSITION: Int = 6;

	public function new(scope: Int = ModelNode.VIEW_MATRIX) {
		super(scope);
	}

	override public function update(frame: Dynamic): Void {
		this.object3d = frame.object;
		super.update(frame);
	}
}

export default ModelNode;

export var modelDirection = nodeImmutable(ModelNode, ModelNode.DIRECTION);
export var modelViewMatrix = nodeImmutable(ModelNode, ModelNode.VIEW_MATRIX).label('modelViewMatrix').temp('ModelViewMatrix');
export var modelNormalMatrix = nodeImmutable(ModelNode, ModelNode.NORMAL_MATRIX);
export var modelWorldMatrix = nodeImmutable(ModelNode, ModelNode.WORLD_MATRIX);
export var modelPosition = nodeImmutable(ModelNode, ModelNode.POSITION);
export var modelScale = nodeImmutable(ModelNode, ModelNode.SCALE);
export var modelViewPosition = nodeImmutable(ModelNode, ModelNode.VIEW_POSITION);

addNodeClass('ModelNode', ModelNode);