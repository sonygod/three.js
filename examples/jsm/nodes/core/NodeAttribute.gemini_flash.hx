class NodeAttribute {

	public var isNodeAttribute:Bool;
	public var name:String;
	public var type:Dynamic;
	public var node:Dynamic;

	public function new(name:String, type:Dynamic, node:Dynamic = null) {
		this.isNodeAttribute = true;
		this.name = name;
		this.type = type;
		this.node = node;
	}
}