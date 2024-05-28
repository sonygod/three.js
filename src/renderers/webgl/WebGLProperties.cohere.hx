class WebGLProperties {
	var properties = new WeakMap<Dynamic, { ? }>();

	public function get(object: Dynamic): { ? } {
		var map = properties.get(object);
		if (map == null) {
			map = { };
			properties.set(object, map);
		}
		return map;
	}

	public function remove(object: Dynamic): Void {
		properties.delete(object);
	}

	public function update(object: Dynamic, key: String, value: Dynamic): Void {
		properties.get(object)[key] = value;
	}

	public function dispose(): Void {
		properties = new WeakMap<Dynamic, { ? }>();
	}
}