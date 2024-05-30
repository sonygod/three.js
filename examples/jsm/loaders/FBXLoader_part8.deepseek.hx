class FBXTree {

    var data:Map<String, Dynamic>;

    public function new() {
        data = new Map();
    }

    public function add(key:String, val:Dynamic) {
        data.set(key, val);
    }

}