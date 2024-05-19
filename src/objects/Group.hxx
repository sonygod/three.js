import three.js.src.core.Object3D;

class Group extends Object3D {

	public function new() {

		super();

		this.isGroup = true;

		this.type = 'Group';

	}

}

typedef Group_three_js_src_objects_Group = Group;