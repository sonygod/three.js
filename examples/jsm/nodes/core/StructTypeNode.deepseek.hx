import three.js.examples.jsm.nodes.core.Node;

class StructTypeNode extends Node {

	public function new(types:Array<Dynamic>) {
		super();
		this.types = types;
		this.isStructTypeNode = true;
	}

	public function getMemberTypes():Array<Dynamic> {
		return this.types;
	}

}

addNodeClass('StructTypeNode', StructTypeNode);