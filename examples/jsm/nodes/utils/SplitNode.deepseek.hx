import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.constants.vectorComponents;

class SplitNode extends Node {

	public function new(node:Node, components:String = "x") {
		super();
		this.node = node;
		this.components = components;
		this.isSplitNode = true;
	}

	public function getVectorLength():Int {
		var vectorLength = this.components.length;
		for (c in this.components) {
			vectorLength = Math.max(vectorComponents.indexOf(c) + 1, vectorLength);
		}
		return vectorLength;
	}

	public function getComponentType(builder:Dynamic):String {
		return builder.getComponentType(this.node.getNodeType(builder));
	}

	public function getNodeType(builder:Dynamic):String {
		return builder.getTypeFromLength(this.components.length, this.getComponentType(builder));
	}

	public function generate(builder:Dynamic, output:String):String {
		var node = this.node;
		var nodeTypeLength = builder.getTypeLength(node.getNodeType(builder));
		var snippet:String = null;
		if (nodeTypeLength > 1) {
			var type:String = null;
			var componentsLength = this.getVectorLength();
			if (componentsLength >= nodeTypeLength) {
				type = builder.getTypeFromLength(this.getVectorLength(), this.getComponentType(builder));
			}
			var nodeSnippet = node.build(builder, type);
			if (this.components.length == nodeTypeLength && this.components == vectorComponents.join("").substr(0, this.components.length)) {
				snippet = builder.format(nodeSnippet, type, output);
			} else {
				snippet = builder.format(nodeSnippet + "." + this.components, this.getNodeType(builder), output);
			}
		} else {
			snippet = node.build(builder, output);
		}
		return snippet;
	}

	public function serialize(data:Dynamic):Void {
		super.serialize(data);
		data.components = this.components;
	}

	public function deserialize(data:Dynamic):Void {
		super.deserialize(data);
		this.components = data.components;
	}
}

addNodeClass('SplitNode', SplitNode);