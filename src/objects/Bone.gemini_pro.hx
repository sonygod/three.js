import core.Object3D;

class Bone extends Object3D {

	public function new() {
		super();
		this.isBone = true;
		this.type = "Bone";
	}

	public var isBone:Bool;
	public var type:String;
}