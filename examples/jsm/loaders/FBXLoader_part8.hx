package three.js.examples.jsm.loaders;

class FBXTree {
    public var data:Dynamic = {};

    public function add(key:String, val:Dynamic) {
        Reflect.setField(data, key, val);
    }
}