package three.js.examples.javascript.renderers.common;

class DataMap {
    private var data:WeakMap<Any, Dynamic>;

    public function new() {
        data = new WeakMap();
    }

    public function get(object:Any):Dynamic {
        var map:Dynamic = data.get(object);
        if (map == null) {
            map = {};
            data.set(object, map);
        }
        return map;
    }

    public function delete(object:Any):Dynamic {
        var map:Dynamic = null;
        if (data.has(object)) {
            map = data.get(object);
            data.delete(object);
        }
        return map;
    }

    public function has(object:Any):Bool {
        return data.has(object);
    }

    public function dispose() {
        data = new WeakMap();
    }
}