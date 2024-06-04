class WebGLProperties {

	private var properties:WeakMap<Dynamic, Dynamic>;

	public function new() {
		this.properties = new WeakMap();
	}

	public function get(object:Dynamic):Dynamic {
		var map = this.properties.get(object);
		if (map == null) {
			map = {};
			this.properties.set(object, map);
		}
		return map;
	}

	public function remove(object:Dynamic):Void {
		this.properties.delete(object);
	}

	public function update(object:Dynamic, key:String, value:Dynamic):Void {
		this.properties.get(object)[key] = value;
	}

	public function dispose():Void {
		this.properties = new WeakMap();
	}

}