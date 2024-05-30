package three.js.nodes.core;

class NodeAttribute {

	public var isNodeAttribute:Bool = true;

	public var name:String;
	public var type:String;
	public var node:Null<Node>; // assuming Node is a type defined elsewhere

	public function new(name:String, type:String, node:Null<Node> = null) {
		this.name = name;
		this.type = type;
		this.node = node;
	}

}