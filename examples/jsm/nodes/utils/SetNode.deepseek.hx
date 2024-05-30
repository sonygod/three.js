import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.core.constants.vectorComponents;

class SetNode extends TempNode {

	public function new(sourceNode:Node, components:Array<String>, targetNode:Node) {

		super();

		this.sourceNode = sourceNode;
		this.components = components;
		this.targetNode = targetNode;

	}

	public function getNodeType(builder:Builder):String {

		return this.sourceNode.getNodeType(builder);

	}

	public function generate(builder:Builder):String {

		var sourceType = this.getNodeType(builder);
		var targetType = builder.getTypeFromLength(components.length);

		var targetSnippet = targetNode.build(builder, targetType);
		var sourceSnippet = sourceNode.build(builder, sourceType);

		var length = builder.getTypeLength(sourceType);
		var snippetValues = [];

		for (i in 0...length) {

			var component = vectorComponents[i];

			if (component == components[0]) {

				snippetValues.push(targetSnippet);

				i += components.length - 1;

			} else {

				snippetValues.push(sourceSnippet + '.' + component);

			}

		}

		return `${builder.getType(sourceType)}(${snippetValues.join(', ')})`;

	}

}

Node.addNodeClass('SetNode', SetNode);