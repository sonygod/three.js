package three.renderers.webgl;

import haxe.ds.WeakMap;

class WebGLProperties {

    var properties:WeakMap<Dynamic, Dynamic>;

    public function new() {
        properties = new WeakMap<Dynamic, Dynamic>();
    }

    public function get(object:Dynamic):Dynamic {
        var map = properties.get(object);
        if (map == null) {
            map = {};
            properties.set(object, map);
        }
        return map;
    }

    public function remove(object:Dynamic):Void {
        properties.remove(object);
    }

    public function update(object:Dynamic, key:String, value:Dynamic):Void {
        var map = properties.get(object);
        if (map != null) {
            map[key] = value;
        }
    }

    public function dispose():Void {
        properties = new WeakMap<Dynamic, Dynamic>();
    }

    public static function create():WebGLProperties {
        return new WebGLProperties();
    }
}