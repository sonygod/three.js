class Cache {
    static public var enabled:Bool = false;
    static public var files:Map<String,Dynamic> = new Map();

    static public function add(key:String, file:Dynamic) {
        if (!enabled) return;
        trace("Cache: Adding key: $key");
        files.set(key, file);
    }

    static public function get(key:String):Dynamic {
        if (!enabled) return null;
        trace("Cache: Checking key: $key");
        return files.get(key);
    }

    static public function remove(key:String) {
        files.remove(key);
    }

    static public function clear() {
        files = new Map();
    }
}