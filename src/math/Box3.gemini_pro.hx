import Vector3 from "./Vector3";

class Box3 {

	public isBox3:Bool = true;

	public min:Vector3;
	public max:Vector3;

	public function new(min:Vector3 = new Vector3(Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY), max:Vector3 = new Vector3(Float.NEGATIVE_INFINITY, Float.NEGATIVE_INFINITY, Float.NEGATIVE_INFINITY)) {
		this.min = min;
		this.max = max;
	}

	public function set(min:Vector3, max:Vector3):Box3 {
		this.min.copy(min);
		this.max.copy(max);
		return this;
	}

	public function setFromArray(array:Array<Float>):Box3 {
		this.makeEmpty();
		for (i in 0...array.length) {
			if (i % 3 == 0) {
				this.expandByPoint(Vector3.fromArray(array, i));
			}
		}
		return this;
	}

	public function setFromBufferAttribute(attribute:BufferAttribute):Box3 {
		this.makeEmpty();
		for (i in 0...attribute.count) {
			this.expandByPoint(Vector3.fromBufferAttribute(attribute, i));
		}
		return this;
	}

	public function setFromPoints(points:Array<Vector3>):Box3 {
		this.makeEmpty();
		for (point in points) {
			this.expandByPoint(point);
		}
		return this;
	}

	public function setFromCenterAndSize(center:Vector3, size:Vector3):Box3 {
		var halfSize = Vector3.copy(size).multiplyScalar(0.5);
		this.min.copy(center).sub(halfSize);
		this.max.copy(center).add(halfSize);
		return this;
	}

	public function setFromObject(object:Object3D, precise:Bool = false):Box3 {
		this.makeEmpty();
		return this.expandByObject(object, precise);
	}

	public function clone():Box3 {
		return new Box3().copy(this);
	}

	public function copy(box:Box3):Box3 {
		this.min.copy(box.min);
		this.max.copy(box.max);
		return this;
	}

	public function makeEmpty():Box3 {
		this.min.x = this.min.y = this.min.z = Float.POSITIVE_INFINITY;
		this.max.x = this.max.y = this.max.z = Float.NEGATIVE_INFINITY;
		return this;
	}

	public function isEmpty():Bool {
		return (this.max.x < this.min.x) || (this.max.y < this.min.y) || (this.max.z < this.min.z);
	}

	public function getCenter(target:Vector3):Vector3 {
		if (this.isEmpty()) {
			return target.set(0, 0, 0);
		} else {
			return target.addVectors(this.min, this.max).multiplyScalar(0.5);
		}
	}

	public function getSize(target:Vector3):Vector3 {
		if (this.isEmpty()) {
			return target.set(0, 0, 0);
		} else {
			return target.subVectors(this.max, this.min);
		}
	}

	public function expandByPoint(point:Vector3):Box3 {
		this.min.min(point);
		this.max.max(point);
		return this;
	}

	public function expandByVector(vector:Vector3):Box3 {
		this.min.sub(vector);
		this.max.add(vector);
		return this;
	}

	public function expandByScalar(scalar:Float):Box3 {
		this.min.addScalar(-scalar);
		this.max.addScalar(scalar);
		return this;
	}

	public function expandByObject(object:Object3D, precise:Bool = false):Box3 {
		object.updateWorldMatrix(false, false);
		var geometry = object.geometry;
		if (geometry != null) {
			var positionAttribute = geometry.getAttribute("position");
			if (precise && positionAttribute != null && !object.isInstancedMesh) {
				for (i in 0...positionAttribute.count) {
					if (object.isMesh) {
						object.getVertexPosition(i, _vector);
					} else {
						_vector.fromBufferAttribute(positionAttribute, i);
					}
					_vector.applyMatrix4(object.matrixWorld);
					this.expandByPoint(_vector);
				}
			} else {
				if (object.boundingBox != null) {
					if (object.boundingBox == null) {
						object.computeBoundingBox();
					}
					_box.copy(object.boundingBox);
				} else {
					if (geometry.boundingBox == null) {
						geometry.computeBoundingBox();
					}
					_box.copy(geometry.boundingBox);
				}
				_box.applyMatrix4(object.matrixWorld);
				this.union(_box);
			}
		}
		var children = object.children;
		for (i in 0...children.length) {
			this.expandByObject(children[i], precise);
		}
		return this;
	}

	public function containsPoint(point:Vector3):Bool {
		return point.x < this.min.x || point.x > this.max.x ||
			point.y < this.min.y || point.y > this.max.y ||
			point.z < this.min.z || point.z > this.max.z ? false : true;
	}

	public function containsBox(box:Box3):Bool {
		return this.min.x <= box.min.x && box.max.x <= this.max.x &&
			this.min.y <= box.min.y && box.max.y <= this.max.y &&
			this.min.z <= box.min.z && box.max.z <= this.max.z;
	}

	public function getParameter(point:Vector3, target:Vector3):Vector3 {
		return target.set(
			(point.x - this.min.x) / (this.max.x - this.min.x),
			(point.y - this.min.y) / (this.max.y - this.min.y),
			(point.z - this.min.z) / (this.max.z - this.min.z)
		);
	}

	public function intersectsBox(box:Box3):Bool {
		return box.max.x < this.min.x || box.min.x > this.max.x ||
			box.max.y < this.min.y || box.min.y > this.max.y ||
			box.max.z < this.min.z || box.min.z > this.max.z ? false : true;
	}

	public function intersectsSphere(sphere:Sphere):Bool {
		this.clampPoint(sphere.center, _vector);
		return _vector.distanceToSquared(sphere.center) <= (sphere.radius * sphere.radius);
	}

	public function intersectsPlane(plane:Plane):Bool {
		var min:Float, max:Float;
		if (plane.normal.x > 0) {
			min = plane.normal.x * this.min.x;
			max = plane.normal.x * this.max.x;
		} else {
			min = plane.normal.x * this.max.x;
			max = plane.normal.x * this.min.x;
		}
		if (plane.normal.y > 0) {
			min += plane.normal.y * this.min.y;
			max += plane.normal.y * this.max.y;
		} else {
			min += plane.normal.y * this.max.y;
			max += plane.normal.y * this.min.y;
		}
		if (plane.normal.z > 0) {
			min += plane.normal.z * this.min.z;
			max += plane.normal.z * this.max.z;
		} else {
			min += plane.normal.z * this.max.z;
			max += plane.normal.z * this.min.z;
		}
		return (min <= -plane.constant && max >= -plane.constant);
	}

	public function intersectsTriangle(triangle:Triangle):Bool {
		if (this.isEmpty()) {
			return false;
		}
		this.getCenter(_center);
		_extents.subVectors(this.max, _center);
		_v0.subVectors(triangle.a, _center);
		_v1.subVectors(triangle.b, _center);
		_v2.subVectors(triangle.c, _center);
		_f0.subVectors(_v1, _v0);
		_f1.subVectors(_v2, _v1);
		_f2.subVectors(_v0, _v2);
		var axes = [
			0, -_f0.z, _f0.y, 0, -_f1.z, _f1.y, 0, -_f2.z, _f2.y,
			_f0.z, 0, -_f0.x, _f1.z, 0, -_f1.x, _f2.z, 0, -_f2.x,
			-_f0.y, _f0.x, 0, -_f1.y, _f1.x, 0, -_f2.y, _f2.x, 0
		];
		if (!satForAxes(axes, _v0, _v1, _v2, _extents)) {
			return false;
		}
		axes = [1, 0, 0, 0, 1, 0, 0, 0, 1];
		if (!satForAxes(axes, _v0, _v1, _v2, _extents)) {
			return false;
		}
		_triangleNormal.crossVectors(_f0, _f1);
		axes = [_triangleNormal.x, _triangleNormal.y, _triangleNormal.z];
		return satForAxes(axes, _v0, _v1, _v2, _extents);
	}

	public function clampPoint(point:Vector3, target:Vector3):Vector3 {
		return target.copy(point).clamp(this.min, this.max);
	}

	public function distanceToPoint(point:Vector3):Float {
		return this.clampPoint(point, _vector).distanceTo(point);
	}

	public function getBoundingSphere(target:Sphere):Sphere {
		if (this.isEmpty()) {
			target.makeEmpty();
		} else {
			this.getCenter(target.center);
			target.radius = this.getSize(_vector).length() * 0.5;
		}
		return target;
	}

	public function intersect(box:Box3):Box3 {
		this.min.max(box.min);
		this.max.min(box.max);
		if (this.isEmpty()) this.makeEmpty();
		return this;
	}

	public function union(box:Box3):Box3 {
		this.min.min(box.min);
		this.max.max(box.max);
		return this;
	}

	public function applyMatrix4(matrix:Matrix4):Box3 {
		if (this.isEmpty()) return this;
		_points[0].set(this.min.x, this.min.y, this.min.z).applyMatrix4(matrix);
		_points[1].set(this.min.x, this.min.y, this.max.z).applyMatrix4(matrix);
		_points[2].set(this.min.x, this.max.y, this.min.z).applyMatrix4(matrix);
		_points[3].set(this.min.x, this.max.y, this.max.z).applyMatrix4(matrix);
		_points[4].set(this.max.x, this.min.y, this.min.z).applyMatrix4(matrix);
		_points[5].set(this.max.x, this.min.y, this.max.z).applyMatrix4(matrix);
		_points[6].set(this.max.x, this.max.y, this.min.z).applyMatrix4(matrix);
		_points[7].set(this.max.x, this.max.y, this.max.z).applyMatrix4(matrix);
		this.setFromPoints(_points);
		return this;
	}

	public function translate(offset:Vector3):Box3 {
		this.min.add(offset);
		this.max.add(offset);
		return this;
	}

	public function equals(box:Box3):Bool {
		return box.min.equals(this.min) && box.max.equals(this.max);
	}

}

var _points:Array<Vector3> = [
	new Vector3(),
	new Vector3(),
	new Vector3(),
	new Vector3(),
	new Vector3(),
	new Vector3(),
	new Vector3(),
	new Vector3()
];

var _vector:Vector3 = new Vector3();
var _box:Box3 = new Box3();
var _v0:Vector3 = new Vector3();
var _v1:Vector3 = new Vector3();
var _v2:Vector3 = new Vector3();
var _f0:Vector3 = new Vector3();
var _f1:Vector3 = new Vector3();
var _f2:Vector3 = new Vector3();
var _center:Vector3 = new Vector3();
var _extents:Vector3 = new Vector3();
var _triangleNormal:Vector3 = new Vector3();
var _testAxis:Vector3 = new Vector3();

function satForAxes(axes:Array<Float>, v0:Vector3, v1:Vector3, v2:Vector3, extents:Vector3):Bool {
	for (i in 0...axes.length) {
		if (i % 3 == 0) {
			_testAxis.fromArray(axes, i);
			var r = extents.x * Math.abs(_testAxis.x) + extents.y * Math.abs(_testAxis.y) + extents.z * Math.abs(_testAxis.z);
			var p0 = v0.dot(_testAxis);
			var p1 = v1.dot(_testAxis);
			var p2 = v2.dot(_testAxis);
			if (Math.max(-Math.max(p0, p1, p2), Math.min(p0, p1, p2)) > r) {
				return false;
			}
		}
	}
	return true;
}

export default Box3;