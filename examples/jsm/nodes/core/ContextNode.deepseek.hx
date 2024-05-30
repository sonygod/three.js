import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class ContextNode extends Node {

	public function new(node:Node, context:Dynamic = {}) {
		super();

		this.isContextNode = true;

		this.node = node;
		this.context = context;
	}

	public function getNodeType(builder:Dynamic):Dynamic {
		return this.node.getNodeType(builder);
	}

	public function setup(builder:Dynamic):Dynamic {
		var previousContext = builder.getContext();

		builder.setContext( {...builder.context, ...this.context} );

		var node = this.node.build(builder);

		builder.setContext(previousContext);

		return node;
	}

	public function generate(builder:Dynamic, output:Dynamic):Dynamic {
		var previousContext = builder.getContext();

		builder.setContext( {...builder.context, ...this.context} );

		var snippet = this.node.build(builder, output);

		builder.setContext(previousContext);

		return snippet;
	}
}

static function context(node:Node, context:Dynamic = {}):ContextNode {
	return new ContextNode(node, context);
}

static function label(node:Node, name:String):ContextNode {
	return context(node, {label: name});
}

ShaderNode.addNodeElement('context', context);
ShaderNode.addNodeElement('label', label);

Node.addNodeClass('ContextNode', ContextNode);