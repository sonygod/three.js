import TempNode;

class JoinNode extends TempNode {
	public var nodes:Array<TempNode>;
	public var nodeType:Null<Int>;

	public function new(nodes:Array<TempNode> = [], nodeType:Null<Int> = null) {
		super(nodeType);
		this.nodes = nodes;
	}

	public function getNodeType(builder:Builder):Int {
		if (nodeType != null) {
			return builder.getVectorType(nodeType);
		}
		return builder.getTypeFromLength(nodes.fold(0, (count, cur) -> count + builder.getTypeLength(cur.getNodeType(builder))));
	}

	public function generate(builder:Builder, output:Boolean) : String {
		var type = getNodeType(builder);
		var nodes = this.nodes;

		var primitiveType = builder.getComponentType(type);

		var snippetValues = [];

		for (node in nodes) {
			var inputSnippet = node.build(builder);
			var inputPrimitiveType = builder.getComponentType(node.getNodeType(builder));

			if (inputPrimitiveType != primitiveType) {
				inputSnippet = builder.format(inputSnippet, inputPrimitiveType, primitiveType);
			}

			snippetValues.push(inputSnippet);
		}

		var snippet = "${builder.getType(type)}(${snippetValues.join(", ")})";

		return builder.format(snippet, type, output);
	}
}

class Builder {
	public function getVectorType(nodeType:Int):Int {
		// ...
	}

	public function getTypeFromLength(length:Int):Int {
		// ...
	}

	public function getComponentType(type:Int):Int {
		// ...
	}

	public function getTypeLength(type:Int):Int {
		// ...
	}

	public function format(snippet:String, type:Int, output:Boolean):String {
		// ...
	}
}

class Node {
	public function build(builder:Builder):String {
		// ...
	}

	public function getNodeType(builder:Builder):Int {
		// ...
	}
}