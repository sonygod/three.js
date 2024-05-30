import js.Node;
import js.TempNode;
import js.NodeUtils.addNodeClass;

class SetNode extends TempNode {
	public var sourceNode:Node;
	public var components:Array<String>;
	public var targetNode:Node;

	public function new(sourceNode:Node, components:Array<String>, targetNode:Node) {
		super();
		this.sourceNode = sourceNode;
		this.components = components;
		this.targetNode = targetNode;
	}

	public function getNodeType(builder:Node.Builder):Node.Type {
		return sourceNode.getNodeType(builder);
	}

	public function generate(builder:Node.Builder):String {
		var sourceNode = this.sourceNode;
		var components = this.components;
		var targetNode = this.targetNode;

		var sourceType = getNodeType(builder);
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

		return '${builder.getType(sourceType)}(${snippetValues.join(', ')})';
	}
}

@:jsRequire('SetNode')
static function default_SetNode() : SetNode;

addNodeClass('SetNode', SetNode);