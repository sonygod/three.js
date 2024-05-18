package three.js.examples.jm.renderers.common;

class DataMap {
    private var data:Map<Dynamic, Dynamic>;

    public function new() {
        data = new Map<Dynamic, Dynamic>();
    }

    public function get(object:Dynamic):Dynamic {
        var map:Dynamic = data.get(object);
        if (map == null) {
            map = {};
            data.set(object, map);
        }
        return map;
    }

    public function delete(object:Dynamic):Dynamic {
        var map:Dynamic = null;
        if (data.exists(object)) {
            map = data.get(object);
            data.remove(object);
        }
        return map;
    }

    public function has(object:Dynamic):Bool {
        return data.exists(object);
    }

    public function dispose():Void {
        data = new Map<Dynamic, Dynamic>();
    }
}