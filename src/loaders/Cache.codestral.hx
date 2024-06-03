class Cache {
    public static var enabled:Bool = false;
    public static var files:Map<String, Dynamic> = new Map<String, Dynamic>();

    public static function add(key:String, file:Dynamic):Void {
        if (enabled == false) return;

        files.set(key, file);
    }

    public static function get(key:String):Dynamic {
        if (enabled == false) return null;

        return files.get(key);
    }

    public static function remove(key:String):Void {
        files.remove(key);
    }

    public static function clear():Void {
        files = new Map<String, Dynamic>();
    }
}