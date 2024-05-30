import Node, { addNodeClass } from './Node.js';

class StructTypeNode extends Node {

	public var types: Array<Dynamic>;

	public function new(types: Array<Dynamic>) {

		super();

		this.types = types;
		this.isStructTypeNode = true;

	}

	public function getMemberTypes(): Array<Dynamic> {

		return this.types;

	}

}

addNodeClass('StructTypeNode', StructTypeNode);