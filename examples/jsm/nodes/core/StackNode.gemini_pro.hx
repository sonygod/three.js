import Node from "./Node";
import CondNode from "../math/CondNode";
import ShaderNode, { nodeProxy, getCurrentStack, setCurrentStack } from "../shadernode/ShaderNode";

class StackNode extends Node {

	public var nodes:Array<Node>;
	public var outputNode:Node;
	public var parent:Node;
	public var _currentCond:CondNode;
	public var isStackNode:Bool = true;

	public function new(parent:Node = null) {
		super();
		this.nodes = new Array<Node>();
		this.outputNode = null;
		this.parent = parent;
		this._currentCond = null;
	}

	public function getNodeType(builder:Dynamic):String {
		return if (this.outputNode != null) this.outputNode.getNodeType(builder) else "void";
	}

	public function add(node:Node):StackNode {
		this.nodes.push(node);
		return this;
	}

	public function `if`(boolNode:Node, method:Dynamic):StackNode {
		var methodNode = new ShaderNode(method);
		this._currentCond = CondNode.cond(boolNode, methodNode);
		return this.add(this._currentCond);
	}

	public function elseif(boolNode:Node, method:Dynamic):StackNode {
		var methodNode = new ShaderNode(method);
		var ifNode = CondNode.cond(boolNode, methodNode);
		this._currentCond.elseNode = ifNode;
		this._currentCond = ifNode;
		return this;
	}

	public function `else`(method:Dynamic):StackNode {
		this._currentCond.elseNode = new ShaderNode(method);
		return this;
	}

	public function build(builder:Dynamic, ?params:Array<Dynamic>):Dynamic {
		var previousStack = getCurrentStack();
		setCurrentStack(this);
		for (node in this.nodes) {
			node.build(builder, "void");
		}
		setCurrentStack(previousStack);
		return if (this.outputNode != null) this.outputNode.build(builder, params) else super.build(builder, params);
	}

}

export default StackNode;

export var stack = nodeProxy(StackNode);

Node.addNodeClass("StackNode", StackNode);