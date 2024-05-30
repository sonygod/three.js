class Binding {
	public var name: String = '';
	public var visibility: Int = 0;

	public function new(name: String = '') {
		this.name = name;
	}

	public function setVisibility(visibility: Int) {
		this.visibility = visibility | this.visibility;
	}

	public function clone(): Binding {
		return Object.assign(new Binding(), this);
	}
}

class Export {
	public static var __default__: Binding = null;
}