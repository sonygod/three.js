package three.js.src.renderers.webgl;

import haxe.ds.WeakMap;

class WebGLProperties {
    private var properties:WeakMap<Any, Map<String, Dynamic>> = new WeakMap();

    public function new() {}

    public function get(object:Any):Map<String, Dynamic> {
        var map:Map<String, Dynamic> = properties.get(object);
        if (map == null) {
            map = new Map<String, Dynamic>();
            properties.set(object, map);
        }
        return map;
    }

    public function remove(object:Any) {
        properties.remove(object);
    }

    public function update(object:Any, key:String, value:Dynamic) {
        var map:Map<String, Dynamic> = properties.get(object);
        if (map != null) {
            map.set(key, value);
        }
    }

    public function dispose() {
        properties = new WeakMap();
    }
}