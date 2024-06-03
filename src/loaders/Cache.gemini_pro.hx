class Cache {

	public var enabled:Bool = false;

	public var files:Map<String,Dynamic> = new Map();

	public function add(key:String, file:Dynamic) {

		if (!this.enabled) return;

		// console.log( 'THREE.Cache', 'Adding key:', key );

		this.files.set(key, file);

	}

	public function get(key:String):Dynamic {

		if (!this.enabled) return;

		// console.log( 'THREE.Cache', 'Checking key:', key );

		return this.files.get(key);

	}

	public function remove(key:String) {

		this.files.remove(key);

	}

	public function clear() {

		this.files = new Map();

	}

}

class Main {

	static function main() {

		var cache = new Cache();

		cache.enabled = true;

		cache.add("key1", "value1");

		trace(cache.get("key1")); // "value1"

		cache.remove("key1");

		trace(cache.get("key1")); // null

	}

}