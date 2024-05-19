import three.js.src.core.Object3D;

class Bone extends Object3D {

	public function new() {

		super();

		this.isBone = true;

		this.type = 'Bone';

	}

}

typedef Bone = three.js.src.objects.Bone;