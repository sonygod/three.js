class Cache {
    public static var enabled:Bool = false;
    public static var files:Map<String, Dynamic> = new Map();

    public static function add(key:String, file:Dynamic):Void {
        if (!enabled) return;
        // trace('THREE.Cache', 'Adding key:', key);
        files.set(key, file);
    }

    public static function get(key:String):Dynamic {
        if (!enabled) return null;
        // trace('THREE.Cache', 'Checking key:', key);
        return files.get(key);
    }

    public static function remove(key:String):Void {
        files.remove(key);
    }

    public static function clear():Void {
        files = new Map();
    }
}