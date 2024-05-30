import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.TempNode;

class JoinNode extends TempNode {

	public function new(nodes:Array<Dynamic> = [], nodeType:String = null) {
		super(nodeType);
		this.nodes = nodes;
	}

	public function getNodeType(builder:Dynamic):String {
		if (this.nodeType !== null) {
			return builder.getVectorType(this.nodeType);
		}
		return builder.getTypeFromLength(this.nodes.reduce((count, cur) -> count + builder.getTypeLength(cur.getNodeType(builder)), 0));
	}

	public function generate(builder:Dynamic, output:String):String {
		var type = this.getNodeType(builder);
		var nodes = this.nodes;
		var primitiveType = builder.getComponentType(type);
		var snippetValues = [];
		for (input in nodes) {
			var inputSnippet = input.build(builder);
			var inputPrimitiveType = builder.getComponentType(input.getNodeType(builder));
			if (inputPrimitiveType !== primitiveType) {
				inputSnippet = builder.format(inputSnippet, inputPrimitiveType, primitiveType);
			}
			snippetValues.push(inputSnippet);
		}
		var snippet = `${builder.getType(type)}(${snippetValues.join(', ')})`;
		return builder.format(snippet, type, output);
	}

}

Node.addNodeClass('JoinNode', JoinNode);