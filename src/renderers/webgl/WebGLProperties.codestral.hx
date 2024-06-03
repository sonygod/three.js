class WebGLProperties {
    private var properties:WeakMap<Dynamic,Dynamic>;

    public function new() {
        properties = new WeakMap<Dynamic,Dynamic>();
    }

    public function get(object:Dynamic):Dynamic {
        var map = properties.get(object);

        if (map == null) {
            map = new haxe.ds.StringMap<Dynamic>();
            properties.set(object, map);
        }

        return map;
    }

    public function remove(object:Dynamic):Void {
        properties.delete(object);
    }

    public function update(object:Dynamic, key:String, value:Dynamic):Void {
        properties.get(object).set(key, value);
    }

    public function dispose():Void {
        properties = new WeakMap<Dynamic,Dynamic>();
    }
}