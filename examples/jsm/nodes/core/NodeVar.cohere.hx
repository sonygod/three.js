class NodeVar {
	public var isNodeVar:Bool = true;
	public var name:String;
	public var type:Dynamic;

	public function new(name:String, type:Dynamic) {
		this.name = name;
		this.type = type;
	}
}

class Export {
	public static function get_default() : NodeVar {
		return NodeVar;
	}
}