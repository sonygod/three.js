class Cache {
    public static var enabled:Bool = false;
    public static var files:Map<String, Dynamic> = new Map();

    public static function add(key:String, file:Dynamic):Void {
        if (!enabled) return;
        files[key] = file;
    }

    public static function get(key:String):Dynamic {
        if (!enabled) return null;
        return files[key];
    }

    public static function remove(key:String):Void {
        files.remove(key);
    }

    public static function clear():Void {
        files = new Map();
    }
}


Please note that Haxe does not have a direct equivalent to JavaScript's `export` statement. Instead, Haxe uses a package system to organize and share code. If you want to use this `Cache` class in another Haxe file, you would need to import it using the `import` statement. For example:


import Cache;


This assumes that the `Cache` class is in the same package as the file where it is being imported. If it is in a different package, you would need to specify the package name in the import statement. For example:


import three.loaders.Cache;