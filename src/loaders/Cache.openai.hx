package three.js.src.loaders;

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

Note that in Haxe, we use `public static` keywords to define static members, and `Map<String, Dynamic>` to define a map with string keys and dynamic values. We also use `trace` instead of `console.log`, but I commented it out since it's not necessary in Haxe.

Also, in Haxe, we don't need to use `export` keyword, instead, we can simply use the `package` declaration to make the `Cache` class accessible from other files.

You can use this Haxe class in a similar way as the JavaScript code, for example:

Cache.enabled = true;
Cache.add("key", "value");
var value = Cache.get("key");
Cache.remove("key");
Cache.clear();