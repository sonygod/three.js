class UniformGroup {
	public var name: String;
	public var isUniformGroup: Bool;

	public function new(name: String) {
		this.name = name;
		this.isUniformGroup = true;
	}
}

class Export {
	public static var __default__: UniformGroup = null;
}