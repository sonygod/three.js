import haxe.ds.WeakMap;

class DataMap {

	public var data:WeakMap<Dynamic, Dynamic>;

	public function new() {
		this.data = new WeakMap<Dynamic, Dynamic>();
	}

	public function get(object:Dynamic):Dynamic {
		var map:Dynamic = this.data.get(object);

		if (map == null) {
			map = {};
			this.data.set(object, map);
		}

		return map;
	}

	public function delete(object:Dynamic):Dynamic {
		var map:Dynamic;

		if (this.data.exists(object)) {
			map = this.data.get(object);
			this.data.remove(object);
		}

		return map;
	}

	public function has(object:Dynamic):Bool {
		return this.data.exists(object);
	}

	public function dispose() {
		this.data = new WeakMap<Dynamic, Dynamic>();
	}
}