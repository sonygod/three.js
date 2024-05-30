import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.AttributeNode;
import three.js.examples.jsm.nodes.core.VaryingNode;
import three.js.examples.jsm.nodes.math.MathNode;
import three.js.examples.jsm.nodes.nodes.ModelNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class PositionNode extends Node {

	public static var GEOMETRY:String = 'geometry';
	public static var LOCAL:String = 'local';
	public static var WORLD:String = 'world';
	public static var WORLD_DIRECTION:String = 'worldDirection';
	public static var VIEW:String = 'view';
	public static var VIEW_DIRECTION:String = 'viewDirection';

	var scope:String;

	public function new(scope:String = LOCAL) {
		super('vec3');
		this.scope = scope;
	}

	public function isGlobal():Bool {
		return true;
	}

	public function getHash(builder:ShaderNode.Builder):String {
		return 'position-${this.scope}';
	}

	public function generate(builder:ShaderNode.Builder):ShaderNode {
		var scope:String = this.scope;
		var outputNode:ShaderNode = null;

		if (scope == GEOMETRY) {
			outputNode = AttributeNode.attribute('position', 'vec3');
		} else if (scope == LOCAL) {
			outputNode = VaryingNode.varying(positionGeometry);
		} else if (scope == WORLD) {
			var vertexPositionNode:ShaderNode = ModelNode.modelWorldMatrix.mul(positionLocal);
			outputNode = VaryingNode.varying(vertexPositionNode);
		} else if (scope == VIEW) {
			var vertexPositionNode:ShaderNode = ModelNode.modelViewMatrix.mul(positionLocal);
			outputNode = VaryingNode.varying(vertexPositionNode);
		} else if (scope == VIEW_DIRECTION) {
			var vertexPositionNode:ShaderNode = positionView.negate();
			outputNode = MathNode.normalize(VaryingNode.varying(vertexPositionNode));
		} else if (scope == WORLD_DIRECTION) {
			var vertexPositionNode:ShaderNode = positionLocal.transformDirection(ModelNode.modelWorldMatrix);
			outputNode = MathNode.normalize(VaryingNode.varying(vertexPositionNode));
		}

		return outputNode.build(builder, this.getNodeType(builder));
	}

	public function serialize(data:Dynamic) {
		super.serialize(data);
		data.scope = this.scope;
	}

	public function deserialize(data:Dynamic) {
		super.deserialize(data);
		this.scope = data.scope;
	}

}

ShaderNode.addNodeClass('PositionNode', PositionNode);

var positionGeometry:ShaderNode = ShaderNode.nodeImmutable(PositionNode, PositionNode.GEOMETRY);
var positionLocal:ShaderNode = ShaderNode.nodeImmutable(PositionNode, PositionNode.LOCAL).temp('Position');
var positionWorld:ShaderNode = ShaderNode.nodeImmutable(PositionNode, PositionNode.WORLD);
var positionWorldDirection:ShaderNode = ShaderNode.nodeImmutable(PositionNode, PositionNode.WORLD_DIRECTION);
var positionView:ShaderNode = ShaderNode.nodeImmutable(PositionNode, PositionNode.VIEW);
var positionViewDirection:ShaderNode = ShaderNode.nodeImmutable(PositionNode, PositionNode.VIEW_DIRECTION);