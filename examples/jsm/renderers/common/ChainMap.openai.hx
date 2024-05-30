package three.js.examples.jsm.renderers.common;

class ChainMap {
    private var weakMap:WeakMap<Dynamic, WeakMap<Dynamic, Dynamic>>;

    public function new() {
        weakMap = new WeakMap();
    }

    public function get(keys:Dynamic) {
        if (Std.isOfType(keys, Array)) {
            var map:WeakMap<Dynamic, Dynamic> = weakMap;
            for (i in 0...cast(keys, Array<Dynamic>).length) {
                map = map.get(cast(keys, Array<Dynamic>)[i]);
                if (map == null) return null;
            }
            return map.get(cast(keys, Array<Dynamic>)[cast(keys, Array<Dynamic>).length - 1]);
        } else {
            // Note: There is no "super" in Haxe, so we can't call super.get here
            // You might need to implement your own get method or find an alternative solution
            // return super.get(keys);
            throw "Not implemented";
        }
    }

    public function set(keys:Dynamic, value:Dynamic) {
        if (Std.isOfType(keys, Array)) {
            var map:WeakMap<Dynamic, Dynamic> = weakMap;
            for (i in 0...cast(keys, Array<Dynamic>).length) {
                var key:Dynamic = cast(keys, Array<Dynamic>)[i];
                if (!map.exists(key)) map.set(key, new WeakMap());
                map = map.get(key);
            }
            return map.set(cast(keys, Array<Dynamic>)[cast(keys, Array<Dynamic>).length - 1], value);
        } else {
            // Note: There is no "super" in Haxe, so we can't call super.set here
            // You might need to implement your own set method or find an alternative solution
            // return super.set(keys, value);
            throw "Not implemented";
        }
    }

    public function delete(keys:Dynamic) {
        if (Std.isOfType(keys, Array)) {
            var map:WeakMap<Dynamic, Dynamic> = weakMap;
            for (i in 0...cast(keys, Array<Dynamic>).length) {
                map = map.get(cast(keys, Array<Dynamic>)[i]);
                if (map == null) return false;
            }
            return map.delete(cast(keys, Array<Dynamic>)[cast(keys, Array<Dynamic>).length - 1]);
        } else {
            // Note: There is no "super" in Haxe, so we can't call super.delete here
            // You might need to implement your own delete method or find an alternative solution
            // return super.delete(keys);
            throw "Not implemented";
        }
    }

    public function dispose() {
        weakMap.clear();
    }
}