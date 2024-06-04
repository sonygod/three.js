import Node from "./Node";
import ShaderNode from "../shadernode/ShaderNode";

class ContextNode extends Node {

	public var isContextNode:Bool = true;
	public var node:Node;
	public var context:Dynamic;

	public function new(node:Node, context:Dynamic = {}) {
		super();
		this.node = node;
		this.context = context;
	}

	public function getNodeType(builder:Dynamic):Dynamic {
		return this.node.getNodeType(builder);
	}

	public function setup(builder:Dynamic):Dynamic {
		var previousContext = builder.getContext();
		builder.setContext(Reflect.copy(builder.context, this.context));
		var node = this.node.build(builder);
		builder.setContext(previousContext);
		return node;
	}

	public function generate(builder:Dynamic, output:Dynamic):Dynamic {
		var previousContext = builder.getContext();
		builder.setContext(Reflect.copy(builder.context, this.context));
		var snippet = this.node.build(builder, output);
		builder.setContext(previousContext);
		return snippet;
	}

}

class ContextNodeProxy {
	public static function new():ContextNodeProxy {
		return new ContextNodeProxy();
	}

	public function __call__(node:Node, context:Dynamic = {}):ContextNode {
		return new ContextNode(node, context);
	}
}

var context = new ContextNodeProxy();
var label = function(node:Node, name:String):ContextNode {
	return context(node, {label: name});
};

ShaderNode.addNodeElement("context", context);
ShaderNode.addNodeElement("label", label);
ShaderNode.addNodeClass("ContextNode", ContextNode);