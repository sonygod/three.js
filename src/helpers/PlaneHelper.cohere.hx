import h3d.BufferAttribute;
import h3d.BufferGeometry;
import h3d.Line;
import h3d.LineBasicMaterial;
import h3d.Mesh;
import h3d.MeshBasicMaterial;

class PlaneHelper extends Line {

	public var plane:Dynamic;
	public var size:Float = 1;

	public function new(plane:Dynamic, size:Float = 1, hex:Int = 0xFFFF00) {
		super(null, null);

		var color = hex;

		var positions = [1, -1, 0, -1, 1, 0, -1, -1, 0, 1, 1, 0, -1, 1, 0, -1, -1, 0, 1, -1, 0, 1, 1, 0];

		var geometry = new BufferGeometry();
		geometry.setAttribute('position', new BufferAttribute(positions, 3));
		geometry.computeBoundingSphere();

		var material = new LineBasicMaterial({ color: color, toneMapped: false });

		super(geometry, material);

		this.type = 'PlaneHelper';
		this.plane = plane;
		this.size = size;

		var positions2 = [1, 1, 0, -1, 1, 0, -1, -1, 0, 1, 1, 0, -1, -1, 0, 1, -1, 0];

		var geometry2 = new BufferGeometry();
		geometry2.setAttribute('position', new BufferAttribute(positions2, 3));
		geometry2.computeBoundingSphere();

		var material2 = new MeshBasicMaterial({ color: color, opacity: 0.2, transparent: true, depthWrite: false, toneMapped: false });

		var mesh = new Mesh(geometry2, material2);
		this.addChild(mesh);
	}

	public function updateMatrixWorld(force:Bool) {
		this.position.set(0, 0, 0);
		this.scale.set(0.5 * this.size, 0.5 * this.size, 1);
		this.lookAt(this.plane.normal);
		this.translateZ(-this.plane.constant);
		super.updateMatrixWorld(force);
	}

	public function dispose() {
		this.geometry.dispose();
		this.material.dispose();
		this.children[0].geometry.dispose();
		this.children[0].material.dispose();
	}

}

class h2d {
	public static function main() {
		// ...
	}
}