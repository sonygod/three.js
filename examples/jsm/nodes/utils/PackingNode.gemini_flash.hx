import TempNode from "../core/TempNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class PackingNode extends TempNode {

	public scope:String;
	public node:Node;

	public function new(scope:String, node:Node) {
		super();
		this.scope = scope;
		this.node = node;
	}

	public function getNodeType(builder:Dynamic):Dynamic {
		return this.node.getNodeType(builder);
	}

	public function setup():Dynamic {

		var result:Dynamic = null;

		if (this.scope == PackingNode.DIRECTION_TO_COLOR) {
			result = this.node.mul(0.5).add(0.5);
		} else if (this.scope == PackingNode.COLOR_TO_DIRECTION) {
			result = this.node.mul(2.0).sub(1);
		}

		return result;
	}

}

PackingNode.DIRECTION_TO_COLOR = "directionToColor";
PackingNode.COLOR_TO_DIRECTION = "colorToDirection";

class PackingNodeProxy extends ShaderNode {

	public function new(type:String) {
		super(type);
	}

	override public function construct(builder:Dynamic):Dynamic {
		return new PackingNode(this.type, builder.getNode(this.input));
	}

}

var directionToColor = new PackingNodeProxy(PackingNode.DIRECTION_TO_COLOR);
var colorToDirection = new PackingNodeProxy(PackingNode.COLOR_TO_DIRECTION);

ShaderNode.addNodeElement("directionToColor", directionToColor);
ShaderNode.addNodeElement("colorToDirection", colorToDirection);

Node.addNodeClass("PackingNode", PackingNode);

export {PackingNode, directionToColor, colorToDirection};