package three.js.examples.jm.renderers.common;

import haxe.ds.WeakMap;

class ChainMap {
    private var weakMap:WeakMap<Dynamic, WeakMap<Dynamic, Dynamic>>;

    public function new() {
        weakMap = new WeakMap();
    }

    public function get(keys:Dynamic):Dynamic {
        if (Std.isOfType(keys, Array)) {
            var map:WeakMap<Dynamic, Dynamic> = weakMap;
            for (i in 0...keys.length) {
                map = map.get(keys[i]);
                if (map == null) return null;
            }
            return map.get(keys[keys.length - 1]);
        } else {
            return super.get(keys);
        }
    }

    public function set(keys:Dynamic, value:Dynamic):Void {
        if (Std.isOfType(keys, Array)) {
            var map:WeakMap<Dynamic, Dynamic> = weakMap;
            for (i in 0...keys.length) {
                var key = keys[i];
                if (!map.exists(key)) map.set(key, new WeakMap());
                map = map.get(key);
            }
            map.set(keys[keys.length - 1], value);
        } else {
            super.set(keys, value);
        }
    }

    public function delete(keys:Dynamic):Bool {
        if (Std.isOfType(keys, Array)) {
            var map:WeakMap<Dynamic, Dynamic> = weakMap;
            for (i in 0...keys.length) {
                map = map.get(keys[i]);
                if (map == null) return false;
            }
            return map.remove(keys[keys.length - 1]);
        } else {
            return super.delete(keys);
        }
    }

    public function dispose():Void {
        weakMap.clear();
    }
}