class NodeAttribute {
	public var isNodeAttribute:Bool = true;
	public var name:String;
	public var type:Dynamic;
	public var node:Dynamic;

	public function new(name:String, type:Dynamic, ?node:Dynamic) {
		this.name = name;
		this.type = type;
		this.node = node ?? null;
	}
}