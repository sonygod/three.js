import Node from "./Node";

class StructTypeNode extends Node {

	public var types:Array<Dynamic>;
	public var isStructTypeNode:Bool = true;

	public function new(types:Array<Dynamic>) {
		super();
		this.types = types;
	}

	public function getMemberTypes():Array<Dynamic> {
		return this.types;
	}
}

Node.addNodeClass("StructTypeNode", StructTypeNode);

export default StructTypeNode;