class ChainMap {

	var weakMap:WeakMap<Dynamic, Dynamic>;

	public function new() {

		weakMap = new WeakMap();

	}

	public function get(keys:Array<Dynamic>):Dynamic {

		if (keys.length > 0) {

			var map = weakMap;

			for (i in 0...keys.length-1) {

				map = cast(map.get(keys[i]), WeakMap);

				if (map == null) return null;

			}

			return map.get(keys[keys.length-1]);

		} else {

			return super.get(keys);

		}

	}

	public function set(keys:Array<Dynamic>, value:Dynamic):Dynamic {

		if (keys.length > 0) {

			var map = weakMap;

			for (i in 0...keys.length-1) {

				var key = keys[i];

				if (!map.has(key)) map.set(key, new WeakMap());

				map = cast(map.get(key), WeakMap);

			}

			return map.set(keys[keys.length-1], value);

		} else {

			return super.set(keys, value);

		}

	}

	public function delete(keys:Array<Dynamic>):Bool {

		if (keys.length > 0) {

			var map = weakMap;

			for (i in 0...keys.length-1) {

				map = cast(map.get(keys[i]), WeakMap);

				if (map == null) return false;

			}

			return map.delete(keys[keys.length-1]);

		} else {

			return super.delete(keys);

		}

	}

	public function dispose():Void {

		weakMap.clear();

	}

}