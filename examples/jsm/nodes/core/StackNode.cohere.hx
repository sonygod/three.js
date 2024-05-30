import Node from './Node.hx';
import { Cond } from '../math/CondNode.hx';
import { ShaderNode, nodeProxy, getCurrentStack, setCurrentStack } from '../shadernode/ShaderNode.hx';

class StackNode extends Node {
	public nodes:Array<Node>;
	public outputNode:Node;
	public parent:Node;
	private _currentCond:Cond;

	public function new(parent:Node = null) {
		super();
		this.nodes = [];
		this.outputNode = null;
		this.parent = parent;
		this._currentCond = null;
	}

	public function getNodeType(builder:Dynamic):String {
		return this.outputNode != null ? this.outputNode.getNodeType(builder) : 'void';
	}

	public function add(node:Node):StackNode {
		this.nodes.push(node);
		return this;
	}

	public function if(boolNode:Node, method:String):StackNode {
		var methodNode = new ShaderNode(method);
		this._currentCond = Cond.cond(boolNode, methodNode);
		return this.add(this._currentCond);
	}

	public function elseif(boolNode:Node, method:String):StackNode {
		var methodNode = new ShaderNode(method);
		var ifNode = Cond.cond(boolNode, methodNode);
		this._currentCond.elseNode = ifNode;
		this._currentCond = ifNode;
		return this;
	}

	public function else(method:String):StackNode {
		this._currentCond.elseNode = new ShaderNode(method);
		return this;
	}

	public function build(builder:Dynamic, ...params):Dynamic {
		var previousStack = getCurrentStack();
		setCurrentStack(this);

		for (node in this.nodes) {
			node.build(builder, 'void');
		}

		setCurrentStack(previousStack);

		if (this.outputNode != null) {
			return this.outputNode.build(builder, ...params);
		} else {
			return super.build(builder, ...params);
		}
	}
}

@:private class StackNodePrivate {
	public static inline var __stackNode:StackNode = new StackNode();
}

@:expose
static function stack():StackNode {
	return StackNodePrivate.__stackNode;
}

class NodeClass {
	public static function add(name:String, node:Node):Void {
		// Add the node class to the Node class
	}
}

NodeClass.add('StackNode', StackNode);