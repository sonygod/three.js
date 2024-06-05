import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.math.Vector3;

class VertexTangentsHelper extends LineSegments {

	public var object:Dynamic;
	public var size:Float;
	public var _v1:Vector3;
	public var _v2:Vector3;

	public function new(object:Dynamic, size:Float = 1, color:Int = 0x00ffff) {
		var geometry = new BufferGeometry();
		var nTangents = cast object.geometry.attributes.tangent.count : Int;
		var positions = new Float32BufferAttribute(nTangents * 2 * 3, 3);
		geometry.setAttribute('position', positions);
		super(geometry, new LineBasicMaterial({color: color, toneMapped: false}));
		this.object = object;
		this.size = size;
		this.type = 'VertexTangentsHelper';
		this.matrixAutoUpdate = false;
		this._v1 = new Vector3();
		this._v2 = new Vector3();
		this.update();
	}

	public function update() {
		this.object.updateMatrixWorld(true);
		var matrixWorld = this.object.matrixWorld;
		var position = this.geometry.attributes.position;
		var objGeometry = this.object.geometry;
		var objPos = objGeometry.attributes.position;
		var objTan = objGeometry.attributes.tangent;
		var idx = 0;
		for (j in 0...objPos.count) {
			this._v1.fromBufferAttribute(objPos, j).applyMatrix4(matrixWorld);
			this._v2.fromBufferAttribute(objTan, j);
			this._v2.transformDirection(matrixWorld).multiplyScalar(this.size).add(this._v1);
			position.setXYZ(idx, this._v1.x, this._v1.y, this._v1.z);
			idx += 1;
			position.setXYZ(idx, this._v2.x, this._v2.y, this._v2.z);
			idx += 1;
		}
		position.needsUpdate = true;
	}

	public function dispose() {
		this.geometry.dispose();
		this.material.dispose();
	}

}