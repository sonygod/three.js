package openfl.geom;

class Vector3 {
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public function new(x:Float, y:Float, z:Float) {
		this.x = x;
		this.y = y;
		this.z = z;
	}
	public function copy(v:Vector3):Vector3 {
		x = v.x;
		y = v.y;
		z = v.z;
		return this;
	}
	public function add(v:Vector3):Vector3 {
		x += v.x;
		y += v.y;
		z += v.z;
		return this;
	}
	public function sub(v:Vector3):Vector3 {
		x -= v.x;
		y -= v.y;
		z -= v.z;
		return this;
	}
	public function multiplyScalar(s:Float):Vector3 {
		x *= s;
		y *= s;
		z *= s;
		return this;
	}
	public function applyMatrix4(m:Matrix4):Vector3 {
		// ...
		return this;
	}
	public function distanceToSquared(v:Vector3):Float {
		var dx = x - v.x;
		var dy = y - v.y;
		var dz = z - v.z;
		return dx * dx + dy * dy + dz * dz;
	}
}

class Matrix4 {
	// ...
}

class Box3 {
	public var isBox3:Bool;
	public var min:Vector3;
	public var max:Vector3;
	public function new(min:Vector3 = null, max:Vector3 = null) {
		isBox3 = true;
		if (min == null) {
			min = new Vector3(Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY);
		}
		if (max == null) {
			max = new Vector3(Float.NEGATIVE_INFINITY, Float.NEGATIVE_INFINITY, Float.NEGATIVE_INFINITY);
		}
		this.min = min;
		this.max = max;
	}
	public function set(min:Vector3, max:Vector3):Box3 {
		this.min.copy(min);
		this.max.copy(max);
		return this;
	}
	public function setFromArray(array:Array<Float>):Box3 {
		makeEmpty();
		var i = 0;
		while (i < array.length) {
			expandByPoint(new Vector3(array[i], array[i + 1], array[i + 2]));
			i += 3;
		}
		return this;
	}
	public function setFromBufferAttribute(attribute:Dynamic):Box3 {
		makeEmpty();
		var i = 0;
		var il = attribute.count;
		while (i < il) {
			expandByPoint(_vector.fromBufferAttribute(attribute, i));
			i++;
		}
		return this;
	}
	public function setFromPoints(points:Array<Vector3>):Box3 {
		makeEmpty();
		var i = 0;
		var il = points.length;
		while (i < il) {
			expandByPoint(points[i]);
			i++;
		}
		return this;
	}
	public function setFromCenterAndSize(center:Vector3, size:Vector3):Box3 {
		var halfSize = _vector.copy(size).multiplyScalar(0.5);
		min.copy(center).sub(halfSize);
		max.copy(center).add(halfSize);
		return this;
	}
	public function setFromObject(object:Dynamic, precise:Bool = false):Box3 {
		makeEmpty();
		return expandByObject(object, precise);
	}
	public function clone():Box3 {
		return new Box3().copy(this);
	}
	public function copy(box:Box3):Box3 {
		min.copy(box.min);
		max.copy(box.max);
		return this;
	}
	public function makeEmpty():Box3 {
		min.x = min.y = min.z = Float.POSITIVE_INFINITY;
		max.x = max.y = max.z = Float.NEGATIVE_INFINITY;
		return this;
	}
	public function isEmpty():Bool {
		return (max.x < min.x) || (max.y < min.y) || (max.z < min.z);
	}
	public function getCenter(target:Vector3):Vector3 {
		return isEmpty() ? target.set(0, 0, 0) : target.addVectors(min, max).multiplyScalar(0.5);
	}
	public function getSize(target:Vector3):Vector3 {
		return isEmpty() ? target.set(0, 0, 0) : target.subVectors(max, min);
	}
	public function expandByPoint(point:Vector3):Box3 {
		min.min(point);
		max.max(point);
		return this;
	}
	public function expandByVector(vector:Vector3):Box3 {
		min.sub(vector);
		max.add(vector);
		return this;
	}
	public function expandByScalar(scalar:Float):Box3 {
		min.addScalar(-scalar);
		max.addScalar(scalar);
		return this;
	}
	public function expandByObject(object:Dynamic, precise:Bool = false):Box3 {
		object.updateWorldMatrix(false, false);
		var geometry = object.geometry;
		if (geometry != null) {
			var positionAttribute = geometry.getAttribute("position");
			if (precise && positionAttribute != null && !object.isInstancedMesh) {
				var i = 0;
				var l = positionAttribute.count;
				while (i < l) {
					if (object.isMesh) {
						object.getVertexPosition(i, _vector);
					} else {
						_vector.fromBufferAttribute(positionAttribute, i);
					}
					_vector.applyMatrix4(object.matrixWorld);
					expandByPoint(_vector);
					i++;
				}
			} else {
				var _box:Box3;
				if (object.boundingBox != null) {
					if (object.boundingBox == null) {
						object.computeBoundingBox();
					}
					_box = _box.copy(object.boundingBox);
				} else {
					if (geometry.boundingBox == null) {
						geometry.computeBoundingBox();
					}
					_box = _box.copy(geometry.boundingBox);
				}
				_box.applyMatrix4(object.matrixWorld);
				union(_box);
			}
		}
		var children = object.children;
		var i = 0;
		var l = children.length;
		while (i < l) {
			expandByObject(children[i], precise);
			i++;
		}
		return this;
	}
	public function containsPoint(point:Vector3):Bool {
		return (point.x < min.x || point.x > max.x) || (point.y < min.y || point.y > max.y) || (point.z < min.z || point.z > max.z) ? false : true;
	}
	public function containsBox(box:Box3):Bool {
		return (min.x <= box.min.x && box.max.x <= max.x) && (min.y <= box.min.y && box.max.y <= max.y) && (min.z <= box.min.z && box.max.z <= max.z);
	}
	public function getParameter(point:Vector3, target:Vector3):Vector3 {
		return target.set((point.x - min.x) / (max.x - min.x), (point.y - min.y) / (max.y - min.y), (point.z - min.z) / (max.z - min.z));
	}
	public function intersectsBox(box:Box3):Bool {
		return (box.max.x < min.x || box.min.x > max.x) || (box.max.y < min.y || box.min.y > max.y) || (box.max.z < min.z || box.min.z > max.z) ? false : true;
	}
	public function intersectsSphere(sphere:Dynamic):Bool {
		clampPoint(sphere.center, _vector);
		return _vector.distanceToSquared(sphere.center) <= (sphere.radius * sphere.radius);
	}
	public function intersectsPlane(plane:Dynamic):Bool {
		var min:Float, max:Float;
		if (plane.normal.x > 0) {
			min = plane.normal.x * min.x;
			max = plane.normal.x * max.x;
		} else {
			min = plane.normal.x * max.x;
			max = plane.normal.x * min.x;
		}
		if (plane.normal.y > 0) {
			min += plane.normal.y * min.y;
			max += plane.normal.y * max.y;
		} else {
			min += plane.normal.y * max.y;
			max += plane.normal.y * min.y;
		}
		if (plane.normal.z > 0) {
			min += plane.normal.z * min.z;
			max += plane.normal.z * max.z;
		} else {
			min += plane.normal.z * max.z;
			max += plane.normal.z * min.z;
		}
		return (min <= -plane.constant && max >= -plane.constant);
	}
	public function intersectsTriangle(triangle:Dynamic):Bool {
		if (isEmpty()) {
			return false;
		}
		getCenter(_center);
		_extents.subVectors(max, _center);
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
		return target.copy(point).clamp(min, max);
	}
	public function distanceToPoint(point:Vector3):Float {
		return clampPoint(point, _vector).distanceTo(point);
	}
	public function getBoundingSphere(target:Dynamic):Dynamic {
		if (isEmpty()) {
			target.makeEmpty();
		} else {
			getCenter(target.center);
			target.radius = getSize(_vector).length() * 0.5;
		}
		return target;
	}
	public function intersect(box:Box3):Box3 {
		min.max(box.min);
		max.min(box.max);
		if (isEmpty()) {
			makeEmpty();
		}
		return this;
	}
	public function union(box:Box3):Box3 {
		min.min(box.min);
		max.max(box.max);
		return this;
	}
	public function applyMatrix4(matrix:Matrix4):Box3 {
		if (isEmpty()) {
			return this;
		}
		_points[0].set(min.x, min.y, min.z).applyMatrix4(matrix);
		_points[1].set(min.x, min.y, max.z).applyMatrix4(matrix);
		_points[2].set(min.x, max.y, min.z).applyMatrix4(matrix);
		_points[3].set(min.x, max.y, max.z).applyMatrix4(matrix);
		_points[4].set(max.x, min.y, min.z).applyMatrix4(matrix);
		_points[5].set(max.x, min.y, max.z).applyMatrix4(matrix);
		_points[6].set(max.x, max.y, min.z).applyMatrix4(matrix);
		_points[7].set(max.x, max.y, max.z).applyMatrix4(matrix);
		setFromPoints(_points);
		return this;
	}
	public function translate(offset:Vector3):Box3 {
		min.add(offset);
		max.add(offset);
		return this;
	}
	public function equals(box:Box3):Bool {
		return box.min.equals(min) && box.max.equals(max);
	}
}

var _points = [
	new Vector3(), new Vector3(), new Vector3(), new Vector3(), new Vector3(), new Vector3(), new Vector3(), new Vector3()
];
var _vector = new Vector3();
var _box = new Box3();
var _v0 = new Vector3();
var _v1 = new Vector3();
var _v2 = new Vector3();
var _f0 = new Vector3();
var _f1 = new Vector3();
var _f2 = new Vector3();
var _center = new Vector3();
var _extents = new Vector3();
var _triangleNormal = new Vector3();
var _testAxis = new Vector3();

function satForAxes(axes:Array<Float>, v0:Vector3, v1:Vector3, v2:Vector3, extents:Vector3):Bool {
	var i = 0;
	var j = axes.length - 3;
	while (i <= j) {
		_testAxis.fromArray(axes, i);
		var r = extents.x * Math.abs(_testAxis.x) + extents.y * Math.abs(_testAxis.y) + extents.z * Math.abs(_testAxis.z);
		var p0 = v0.dot(_testAxis);
		var p1 = v1.dot(_testAxis);
		var p2 = v2.dot(_testAxis);
		if (Math.max(-Math.max(p0, p1, p2), Math.min(p0, p1, p2)) > r) {
			return false;
		}
		i += 3;
	}
	return true;
}