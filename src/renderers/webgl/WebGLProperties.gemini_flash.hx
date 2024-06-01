class WebGLProperties {

	private var properties:WeakMap<Dynamic,Dynamic> = new WeakMap();

	public function get(object:Dynamic):Dynamic {
		var map = properties.get(object);
		if (map == null) {
			map = {};
			properties.set(object, map);
		}
		return map;
	}

	public function remove(object:Dynamic):Void {
		properties.delete(object);
	}

	public function update(object:Dynamic, key:String, value:Dynamic):Void {
		properties.get(object)[key] = value;
	}

	public function dispose():Void {
		properties = new WeakMap();
	}
}