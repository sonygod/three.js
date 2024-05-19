class Cache {

    static var enabled:Bool = false;
    static var files:Map<String, Dynamic> = new Map();

    static function add(key:String, file:Dynamic) {
        if (!enabled) return;
        // trace('THREE.Cache', 'Adding key:', key);
        files[key] = file;
    }

    static function get(key:String):Dynamic {
        if (!enabled) return null;
        // trace('THREE.Cache', 'Checking key:', key);
        return files[key];
    }

    static function remove(key:String) {
        files.remove(key);
    }

    static function clear() {
        files.clear();
    }
}