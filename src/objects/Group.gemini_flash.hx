package ;

import three.core.Object3D;

class Group extends Object3D {

	public function new() {
		super();

		this.isGroup = true;

		this.type = 'Group';
	}

}