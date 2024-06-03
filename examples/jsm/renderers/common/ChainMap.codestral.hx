class ChainMap {
    private var weakMap:haxe.ds.WeakMap;

    public function new() {
        this.weakMap = new haxe.ds.WeakMap();
    }

    public function get(keys:Array<Dynamic>):Dynamic {
        if (Std.isOfType(keys, Array)) {
            var map = this.weakMap;
            for (i in 0...keys.length) {
                map = map.get(keys[i]);
                if (map == null) return null;
            }
            return map.get(keys[keys.length - 1]);
        } else {
            // Haxe doesn't support super keyword in this way, so you may need to override get method in your subclass if needed
            return null;
        }
    }

    public function set(keys:Array<Dynamic>, value:Dynamic):Void {
        if (Std.isOfType(keys, Array)) {
            var map = this.weakMap;
            for (i in 0...keys.length) {
                let key = keys[i];
                if (!map.exists(key)) map.set(key, new haxe.ds.WeakMap());
                map = map.get(key);
            }
            map.set(keys[keys.length - 1], value);
        } else {
            // Haxe doesn't support super keyword in this way, so you may need to override set method in your subclass if needed
        }
    }

    public function delete(keys:Array<Dynamic>):Bool {
        if (Std.isOfType(keys, Array)) {
            var map = this.weakMap;
            for (i in 0...keys.length) {
                map = map.get(keys[i]);
                if (map == null) return false;
            }
            return map.remove(keys[keys.length - 1]);
        } else {
            // Haxe doesn't support super keyword in this way, so you may need to override delete method in your subclass if needed
            return false;
        }
    }

    public function dispose():Void {
        this.weakMap = new haxe.ds.WeakMap();
    }
}