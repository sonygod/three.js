import Node from './Node';
import addNodeClass from './Node';
import { cond } from '../math/CondNode';
import ShaderNode from '../shadernode/ShaderNode';
import { nodeProxy, getCurrentStack, setCurrentStack } from '../shadernode/ShaderNode';

class StackNode extends Node {

	public var nodes:Array<Node> = [];
	public var outputNode:Node = null;
	public var parent:Node = null;
	public var _currentCond:Node = null;
	public var isStackNode:Bool = true;

	public function new(parent:Node = null) {
		super();
		this.parent = parent;
	}

	public function getNodeType(builder):String {
		return this.outputNode != null ? this.outputNode.getNodeType(builder) : 'void';
	}

	public function add(node:Node):StackNode {
		this.nodes.push(node);
		return this;
	}

	public function if(boolNode:Node, method:Dynamic):StackNode {
		var methodNode = new ShaderNode(method);
		this._currentCond = cond(boolNode, methodNode);
		return this.add(this._currentCond);
	}

	public function elseif(boolNode:Node, method:Dynamic):StackNode {
		var methodNode = new ShaderNode(method);
		var ifNode = cond(boolNode, methodNode);
		this._currentCond.elseNode = ifNode;
		this._currentCond = ifNode;
		return this;
	}

	public function else(method:Dynamic):StackNode {
		this._currentCond.elseNode = new ShaderNode(method);
		return this;
	}

	public function build(builder:Dynamic, params:Dynamic...):Dynamic {
		var previousStack = getCurrentStack();
		setCurrentStack(this);

		for (node in this.nodes) {
			node.build(builder, 'void');
		}

		setCurrentStack(previousStack);
		return this.outputNode != null ? this.outputNode.build(builder, params) : super.build(builder, params);
	}
}

export default StackNode;

export var stack = nodeProxy(StackNode);

addNodeClass('StackNode', StackNode);