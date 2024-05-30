import haxe.ds.WeakMap;

class ChainMap {

	var weakMap:WeakMap<Dynamic, WeakMap<Dynamic, Dynamic>>;

	public function new() {
		this.weakMap = new WeakMap();
	}

	public function get(keys:Array<Dynamic>):Dynamic {
		if (Type.isArray(keys)) {
			var map:WeakMap<Dynamic, Dynamic> = this.weakMap;
			for (i in 0...keys.length) {
				map = map.get(keys[i]);
				if (map == null) return null;
			}
			return map.get(keys[keys.length - 1]);
		} else {
			return super.get(keys);
		}
	}

	public function set(keys:Array<Dynamic>, value:Dynamic):Dynamic {
		if (Type.isArray(keys)) {
			var map:WeakMap<Dynamic, Dynamic> = this.weakMap;
			for (i in 0...keys.length) {
				var key = keys[i];
				if (!map.exists(key)) map.set(key, new WeakMap());
				map = map.get(key);
			}
			return map.set(keys[keys.length - 1], value);
		} else {
			return super.set(keys, value);
		}
	}

	public function delete(keys:Array<Dynamic>):Bool {
		if (Type.isArray(keys)) {
			var map:WeakMap<Dynamic, Dynamic> = this.weakMap;
			for (i in 0...keys.length) {
				map = map.get(keys[i]);
				if (map == null) return false;
			}
			return map.remove(keys[keys.length - 1]);
		} else {
			return super.delete(keys);
		}
	}

	public function dispose() {
		this.weakMap.clear();
	}
}