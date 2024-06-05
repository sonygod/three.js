import Node from '../core/Node';
import AttributeNode from '../core/AttributeNode';
import VaryingNode from '../core/VaryingNode';
import MathNode from '../math/MathNode';
import ModelNode from './ModelNode';
import ShaderNode from '../shadernode/ShaderNode';

class PositionNode extends Node {

	public static GEOMETRY:String = 'geometry';
	public static LOCAL:String = 'local';
	public static WORLD:String = 'world';
	public static WORLD_DIRECTION:String = 'worldDirection';
	public static VIEW:String = 'view';
	public static VIEW_DIRECTION:String = 'viewDirection';

	public scope:String;

	public function new(scope:String = PositionNode.LOCAL) {
		super('vec3');
		this.scope = scope;
	}

	public function isGlobal():Bool {
		return true;
	}

	public function getHash(/*builder*/):String {
		return 'position-${this.scope}';
	}

	public function generate(builder:Dynamic):Dynamic {
		var scope = this.scope;

		var outputNode:Dynamic = null;

		if (scope == PositionNode.GEOMETRY) {
			outputNode = AttributeNode.attribute('position', 'vec3');
		} else if (scope == PositionNode.LOCAL) {
			outputNode = VaryingNode.varying(positionGeometry);
		} else if (scope == PositionNode.WORLD) {
			var vertexPositionNode = ModelNode.modelWorldMatrix.mul(positionLocal);
			outputNode = VaryingNode.varying(vertexPositionNode);
		} else if (scope == PositionNode.VIEW) {
			var vertexPositionNode = ModelNode.modelViewMatrix.mul(positionLocal);
			outputNode = VaryingNode.varying(vertexPositionNode);
		} else if (scope == PositionNode.VIEW_DIRECTION) {
			var vertexPositionNode = positionView.negate();
			outputNode = MathNode.normalize(VaryingNode.varying(vertexPositionNode));
		} else if (scope == PositionNode.WORLD_DIRECTION) {
			var vertexPositionNode = positionLocal.transformDirection(ModelNode.modelWorldMatrix);
			outputNode = MathNode.normalize(VaryingNode.varying(vertexPositionNode));
		}

		return outputNode.build(builder, this.getNodeType(builder));
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

var positionGeometry = ShaderNode.nodeImmutable(PositionNode, PositionNode.GEOMETRY);
var positionLocal = ShaderNode.nodeImmutable(PositionNode, PositionNode.LOCAL).temp('Position');
var positionWorld = ShaderNode.nodeImmutable(PositionNode, PositionNode.WORLD);
var positionWorldDirection = ShaderNode.nodeImmutable(PositionNode, PositionNode.WORLD_DIRECTION);
var positionView = ShaderNode.nodeImmutable(PositionNode, PositionNode.VIEW);
var positionViewDirection = ShaderNode.nodeImmutable(PositionNode, PositionNode.VIEW_DIRECTION);

ShaderNode.addNodeClass('PositionNode', PositionNode);

export default PositionNode;