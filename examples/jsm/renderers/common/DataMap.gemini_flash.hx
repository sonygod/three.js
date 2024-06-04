class DataMap {

	public var data:WeakMap<Dynamic,Dynamic>;

	public function new() {
		this.data = new WeakMap();
	}

	public function get(object:Dynamic):Dynamic {
		var map = this.data.get(object);
		if (map == null) {
			map = {};
			this.data.set(object, map);
		}
		return map;
	}

	public function delete(object:Dynamic):Dynamic {
		var map:Dynamic;
		if (this.data.has(object)) {
			map = this.data.get(object);
			this.data.delete(object);
		}
		return map;
	}

	public function has(object:Dynamic):Bool {
		return this.data.has(object);
	}

	public function dispose() {
		this.data = new WeakMap();
	}

}