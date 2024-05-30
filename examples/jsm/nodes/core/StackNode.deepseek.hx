import Node;
import CondNode;
import ShaderNode;

class StackNode extends Node {

	public function new(parent:Null<Node> = null) {
		super();
		this.nodes = [];
		this.outputNode = null;
		this.parent = parent;
		this._currentCond = null;
		this.isStackNode = true;
	}

	public function getNodeType(builder:ShaderNode):String {
		return this.outputNode ? this.outputNode.getNodeType(builder) : 'void';
	}

	public function add(node:ShaderNode):StackNode {
		this.nodes.push(node);
		return this;
	}

	public function if(boolNode:ShaderNode, method:ShaderNode):StackNode {
		this._currentCond = CondNode.cond(boolNode, method);
		return this.add(this._currentCond);
	}

	public function elseif(boolNode:ShaderNode, method:ShaderNode):StackNode {
		var ifNode = CondNode.cond(boolNode, method);
		this._currentCond.elseNode = ifNode;
		this._currentCond = ifNode;
		return this;
	}

	public function else(method:ShaderNode):StackNode {
		this._currentCond.elseNode = method;
		return this;
	}

	public function build(builder:ShaderNode, params:Array<Dynamic>):Dynamic {
		var previousStack = ShaderNode.getCurrentStack();
		ShaderNode.setCurrentStack(this);
		for (node in this.nodes) {
			node.build(builder, 'void');
		}
		ShaderNode.setCurrentStack(previousStack);
		return this.outputNode ? this.outputNode.build(builder, params) : super.build(builder, params);
	}

}

static function stack(node:ShaderNode):StackNode {
	return new StackNode(node);
}

static function addNodeClass(name:String, node:StackNode):Void {
	Node.addNodeClass(name, node);
}