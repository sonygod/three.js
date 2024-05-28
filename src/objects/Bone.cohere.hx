package openfl.display3D;

class Bone extends openfl.display3D.Object3D {
	public function new() {
		super();
		this.isBone = true;
		this.setType("Bone");
	}
}