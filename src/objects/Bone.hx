package three.objects;

import three.core.Object3D;

class Bone extends Object3D {

	public function new() {
		super();
		this.isBone = true;
		this.type = 'Bone';
	}

}