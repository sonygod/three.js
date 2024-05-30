import Object3DNode from './Object3DNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { nodeImmutable } from '../shadernode/ShaderNode.hx';

class ModelNode extends Object3DNode {

	public static var VIEW_MATRIX:String = "viewMatrix";
	public static var DIRECTION:String = "direction";
	public static var NORMAL_MATRIX:String = "normalMatrix";
	public static var WORLD_MATRIX:String = "worldMatrix";
	public static var POSITION:String = "position";
	public static var SCALE:String = "scale";
	public static var VIEW_POSITION:String = "viewPosition";

	public function new(scope:String = VIEW_MATRIX) {
		super(scope);
	}

	public function update(frame:Dynamic):Void {
		this.object3d = frame.object;
		super.update(frame);
	}

}

var modelDirection = nodeImmutable(ModelNode, ModelNode.DIRECTION);
var modelViewMatrix = nodeImmutable(ModelNode, ModelNode.VIEW_MATRIX).label('modelViewMatrix').temp('ModelViewMatrix');
var modelNormalMatrix = nodeImmutable(ModelNode, ModelNode.NORMAL_MATRIX);
var modelWorldMatrix = nodeImmutable(ModelNode, ModelNode.WORLD_MATRIX);
var modelPosition = nodeImmutable(ModelNode, ModelNode.POSITION);
var modelScale = nodeImmutable(ModelNode, ModelNode.SCALE);
var modelViewPosition = nodeImmutable(ModelNode, ModelNode.VIEW_POSITION);

addNodeClass('ModelNode', ModelNode);