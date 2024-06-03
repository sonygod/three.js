import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.math.Vector3;

class VertexTangentsHelper extends LineSegments {

	public var object:Dynamic;
	public var size:Float;

	public function new(object:Dynamic, size:Float = 1, color:Int = 0x00ffff) {
		var geometry = new BufferGeometry();

		var nTangents = cast object.geometry.attributes.tangent.count : Int;
		var positions = new Float32BufferAttribute(nTangents * 2 * 3, 3);

		geometry.setAttribute('position', positions);

		super(geometry, new LineBasicMaterial({color:color, toneMapped:false}));

		this.object = object;
		this.size = size;
		this.type = 'VertexTangentsHelper';

		this.matrixAutoUpdate = false;

		this.update();
	}

	public function update():Void {
		this.object.updateMatrixWorld(true);

		var matrixWorld = this.object.matrixWorld;

		var position = this.geometry.attributes.position;

		var objGeometry = this.object.geometry;

		var objPos = objGeometry.attributes.position;
		var objTan = objGeometry.attributes.tangent;

		var _v1 = new Vector3();
		var _v2 = new Vector3();

		var idx = 0;

		for (j in 0...objPos.count) {
			_v1.fromBufferAttribute(objPos, j).applyMatrix4(matrixWorld);
			_v2.fromBufferAttribute(objTan, j);

			_v2.transformDirection(matrixWorld).multiplyScalar(this.size).add(_v1);

			position.setXYZ(idx, _v1.x, _v1.y, _v1.z);
			idx += 1;
			position.setXYZ(idx, _v2.x, _v2.y, _v2.z);
			idx += 1;
		}

		position.needsUpdate = true;
	}

	public function dispose():Void {
		this.geometry.dispose();
		this.material.dispose();
	}

}