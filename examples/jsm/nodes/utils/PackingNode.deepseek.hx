import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class PackingNode extends TempNode {

	var scope:String;
	var node:ShaderNode;

	public function new(scope:String, node:ShaderNode) {
		super();
		this.scope = scope;
		this.node = node;
	}

	public function getNodeType(builder:ShaderNode):String {
		return this.node.getNodeType(builder);
	}

	public function setup():ShaderNode {
		var result:ShaderNode = null;
		if (this.scope == PackingNode.DIRECTION_TO_COLOR) {
			result = this.node.mul(0.5).add(0.5);
		} else if (this.scope == PackingNode.COLOR_TO_DIRECTION) {
			result = this.node.mul(2.0).sub(1);
		}
		return result;
	}

	static var DIRECTION_TO_COLOR:String = 'directionToColor';
	static var COLOR_TO_DIRECTION:String = 'colorToDirection';

}

static function directionToColor(node:ShaderNode):ShaderNode {
	return ShaderNode.nodeProxy(PackingNode, PackingNode.DIRECTION_TO_COLOR, node);
}

static function colorToDirection(node:ShaderNode):ShaderNode {
	return ShaderNode.nodeProxy(PackingNode, PackingNode.COLOR_TO_DIRECTION, node);
}

ShaderNode.addNodeElement('directionToColor', directionToColor);
ShaderNode.addNodeElement('colorToDirection', colorToDirection);

Node.addNodeClass('PackingNode', PackingNode);