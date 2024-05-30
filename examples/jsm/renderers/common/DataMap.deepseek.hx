class DataMap {

	var data:WeakMap<Dynamic, Dynamic>;

	public function new() {

		data = new WeakMap();

	}

	public function get(object:Dynamic):Dynamic {

		var map = data.get(object);

		if (map == null) {

			map = {};
			data.set(object, map);

		}

		return map;

	}

	public function delete(object:Dynamic):Dynamic {

		var map:Dynamic;

		if (data.has(object)) {

			map = data.get(object);

			data.delete(object);

		}

		return map;

	}

	public function has(object:Dynamic):Bool {

		return data.has(object);

	}

	public function dispose():Void {

		data = new WeakMap();

	}

}