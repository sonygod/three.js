package three.js.loaders;

class FBXTree {
	public function new() {}

	public function add(key:String, val:Dynamic) {
		thisReflect.setField(this, key, val);
	}
}