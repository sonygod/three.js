import core.Node;
import core.TempNode;
import core.constants.vectorComponents;

class SetNode extends TempNode {

	public var sourceNode:TempNode;
	public var components:Array<String>;
	public var targetNode:TempNode;

	public function new(sourceNode:TempNode, components:Array<String>, targetNode:TempNode) {
		super();
		this.sourceNode = sourceNode;
		this.components = components;
		this.targetNode = targetNode;
	}

	public function getNodeType(builder:Node):String {
		return this.sourceNode.getNodeType(builder);
	}

	public function generate(builder:Node):String {
		var sourceType = this.getNodeType(builder);
		var targetType = builder.getTypeFromLength(this.components.length);

		var targetSnippet = this.targetNode.build(builder, targetType);
		var sourceSnippet = this.sourceNode.build(builder, sourceType);

		var length = builder.getTypeLength(sourceType);
		var snippetValues = new Array<String>();

		for (i in 0...length) {
			var component = vectorComponents[i];

			if (component == this.components[0]) {
				snippetValues.push(targetSnippet);
				i += this.components.length - 1;
			} else {
				snippetValues.push(sourceSnippet + '.' + component);
			}
		}

		return '${builder.getType(sourceType)}( ${snippetValues.join(', ')} )';
	}
}

Node.addNodeClass('SetNode', SetNode);