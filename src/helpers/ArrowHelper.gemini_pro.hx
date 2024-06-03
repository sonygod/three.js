import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.core.Object3D;
import three.geometries.CylinderGeometry;
import three.materials.LineBasicMaterial;
import three.materials.MeshBasicMaterial;
import three.objects.Line;
import three.objects.Mesh;
import three.math.Vector3;

class ArrowHelper extends Object3D {

	static var _lineGeometry:BufferGeometry;
	static var _coneGeometry:BufferGeometry;

	public var line:Line;
	public var cone:Mesh;

	public function new(dir:Vector3 = new Vector3(0, 0, 1), origin:Vector3 = new Vector3(0, 0, 0), length:Float = 1, color:Int = 0xffff00, headLength:Float = length * 0.2, headWidth:Float = headLength * 0.2) {
		super();
		this.type = "ArrowHelper";

		if (_lineGeometry == null) {
			_lineGeometry = new BufferGeometry();
			_lineGeometry.setAttribute("position", new BufferAttribute(new Float32Array([0, 0, 0, 0, 1, 0]), 3));

			_coneGeometry = new CylinderGeometry(0, 0.5, 1, 5, 1);
			_coneGeometry.translate(0, -0.5, 0);
		}

		this.position.copy(origin);

		this.line = new Line(_lineGeometry, new LineBasicMaterial({color: color, toneMapped: false}));
		this.line.matrixAutoUpdate = false;
		this.add(this.line);

		this.cone = new Mesh(_coneGeometry, new MeshBasicMaterial({color: color, toneMapped: false}));
		this.cone.matrixAutoUpdate = false;
		this.add(this.cone);

		this.setDirection(dir);
		this.setLength(length, headLength, headWidth);
	}

	public function setDirection(dir:Vector3):Void {
		// dir is assumed to be normalized

		if (dir.y > 0.99999) {
			this.quaternion.set(0, 0, 0, 1);
		} else if (dir.y < -0.99999) {
			this.quaternion.set(1, 0, 0, 0);
		} else {
			var _axis = new Vector3(dir.z, 0, -dir.x).normalize();
			var radians = Math.acos(dir.y);
			this.quaternion.setFromAxisAngle(_axis, radians);
		}
	}

	public function setLength(length:Float, headLength:Float = length * 0.2, headWidth:Float = headLength * 0.2):Void {
		this.line.scale.set(1, Math.max(0.0001, length - headLength), 1); // see #17458
		this.line.updateMatrix();

		this.cone.scale.set(headWidth, headLength, headWidth);
		this.cone.position.y = length;
		this.cone.updateMatrix();
	}

	public function setColor(color:Int):Void {
		this.line.material.color.set(color);
		this.cone.material.color.set(color);
	}

	public function copy(source:ArrowHelper):ArrowHelper {
		super.copy(source, false);
		this.line.copy(source.line);
		this.cone.copy(source.cone);
		return this;
	}

	public function dispose():Void {
		this.line.geometry.dispose();
		this.line.material.dispose();
		this.cone.geometry.dispose();
		this.cone.material.dispose();
	}
}