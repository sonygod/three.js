import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.materials.LineBasicMaterial;
import three.objects.LineSegments;
import three.math.Box3;

class Box3Helper extends LineSegments {

	public var box:Box3;

	public function new(box:Box3, color:Int = 0xffff00) {
		var indices = new Uint16Array([0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, 0, 4, 1, 5, 2, 6, 3, 7]);
		var positions = [1, 1, 1, -1, 1, 1, -1, -1, 1, 1, -1, 1, 1, 1, -1, -1, 1, -1, -1, -1, -1, 1, -1, -1];

		var geometry = new BufferGeometry();
		geometry.setIndex(new BufferAttribute(indices, 1));
		geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));

		super(geometry, new LineBasicMaterial({color: color, toneMapped: false}));

		this.box = box;
		this.type = 'Box3Helper';
		this.geometry.computeBoundingSphere();
	}

	override public function updateMatrixWorld(force:Bool) {
		if (this.box.isEmpty()) return;
		this.box.getCenter(this.position);
		this.box.getSize(this.scale);
		this.scale.multiplyScalar(0.5);
		super.updateMatrixWorld(force);
	}

	public function dispose() {
		this.geometry.dispose();
		this.material.dispose();
	}
}