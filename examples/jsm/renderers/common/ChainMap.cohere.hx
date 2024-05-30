class ChainMap {
	var weakMap: WeakMap<Dynamic, Dynamic>;

	public function new() {
		weakMap = WeakMap<Dynamic, Dynamic>();
	}

	public function get(keys: Array<Dynamic>) : Dynamic {
		if (keys.isArray()) {
			var map = weakMap;
			for (key in keys) {
				map = map.get(keys[key]);
				if (map == null) return null;
			}
			return map.get(keys[keys.length - 1]);
		} else {
			return super.get(keys);
		}
	}

	public function set(keys: Array<Dynamic>, value: Dynamic) : Void {
		if (keys.isArray()) {
			var map = weakMap;
			for (key in keys) {
				if (!map.has(keys[key])) map.set(keys[key], WeakMap<Dynamic, Dynamic>());
				map = map.get(keys[key]);
			}
			return map.set(keys[keys.length - 1], value);
		} else {
			return super.set(keys, value);
		}
	}

	public function delete(keys: Array<Dynamic>) : Bool {
		if (keys.isArray()) {
			var map = weakMap;
			for (key in keys) {
				map = map.get(keys[key]);
				if (map == null) return false;
			}
			return map.delete(keys[keys.length - 1]);
		} else {
			return super.delete(keys);
		}
	}

	public function dispose() : Void {
		weakMap.clear();
	}
}