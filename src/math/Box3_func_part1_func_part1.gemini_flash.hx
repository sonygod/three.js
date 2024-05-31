import three.math.Vector3;

class Box3 {

	public var isBox3:Bool = true;

	public var min:Vector3;
	public var max:Vector3;

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
				this.expandByPoint(new Vector3(array[i], array[i + 1], array[i + 2]));
			}
		}
		return this;
	}

	public function setFromBufferAttribute(attribute:haxe.io.Bytes):Box3 {
		this.makeEmpty();
		for (i in 0...attribute.length) {
			if (i % 3 == 0) {
				this.expandByPoint(new Vector3(attribute.getFloat(i), attribute.getFloat(i + 1), attribute.getFloat(i + 2)));
			}
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
		var halfSize = new Vector3().copy(size).multiplyScalar(0.5);
		this.min.copy(center).sub(halfSize);
		this.max.copy(center).add(halfSize);
		return this;
	}

	public function setFromObject(object:Dynamic, precise:Bool = false):Box3 {
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

	public function expandByObject(object:Dynamic, precise:Bool = false):Box3 {
		// Computes the world-axis-aligned bounding box of an object (including its children),
		// accounting for both the object's, and children's, world transforms

		// ... (implementation details for expandByObject) ...

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
		// This can potentially have a divide by zero if the box
		// has a size dimension of 0.

		return target.set(
			(point.x - this.min.x) / (this.max.x - this.min.x),
			(point.y - this.min.y) / (this.max.y - this.min.y),
			(point.z - this.min.z) / (this.max.z - this.min.z)
		);
	}

	public function intersectsBox(box:Box3):Bool {
		// using 6 splitting planes to rule out intersections.
		return box.max.x < this.min.x || box.min.x > this.max.x ||
			box.max.y < this.min.y || box.min.y > this.max.y ||
			box.max.z < this.min.z || box.min.z > this.max.z ? false : true;
	}

	public function intersectsSphere(sphere:Dynamic):Bool {
		// Find the point on the AABB closest to the sphere center.
		this.clampPoint(sphere.center, _vector);

		// If that point is inside the sphere, the AABB and sphere intersect.
		return _vector.distanceToSquared(sphere.center) <= (sphere.radius * sphere.radius);
	}

	public function intersectsPlane(plane:Dynamic):Bool {
		// We compute the minimum and maximum dot product values. If those values
		// are on the same side (back or front) of the plane, then there is no intersection.

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

	public function intersectsTriangle(triangle:Dynamic):Bool {
		if (this.isEmpty()) {
			return false;
		}

		// compute box center and extents
		this.getCenter(_center);
		_extents.subVectors(this.max, _center);

		// translate triangle to aabb origin
		_v0.subVectors(triangle.a, _center);
		_v1.subVectors(triangle.b, _center);
		_v2.subVectors(triangle.c, _center);

		// compute edge vectors for triangle
		_f0.subVectors(_v1, _v0);
		_f1.subVectors(_v2, _v1);
		_f2.subVectors(_v0, _v2);

		// test against axes that are given by cross product combinations of the edges of the triangle and the edges of the aabb
		// make an axis testing of each of the 3 sides of the aabb against each of the 3 sides of the triangle = 9 axis of separation
		// axis_ij = u_i x f_j (u0, u1, u2 = face normals of aabb = x,y,z axes vectors since aabb is axis aligned)
		var axes = [
			0, -_f0.z, _f0.y, 0, -_f1.z, _f1.y, 0, -_f2.z, _f2.y,
			_f0.z, 0, -_f0.x, _f1.z, 0, -_f1.x, _f2.z, 0, -_f2.x,
			-_f0.y, _f0.x, 0, -_f1.y, _f1.x, 0, -_f2.y, _f2.x, 0
		];
		if (!satForAxes(axes, _v0, _v1, _v2, _extents)) {
			return false;
		}

		// test 3 face normals from the aabb
		axes = [1, 0, 0, 0, 1, 0, 0, 0, 1];
		if (!satForAxes(axes, _v0, _v1, _v2, _extents)) {
			return false;
		}

		// finally testing the face normal of the triangle
		// use already existing triangle edge vectors here
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

	public function getBoundingSphere(target:Dynamic):Dynamic {
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

		// ensure that if there is no overlap, the result is fully empty, not slightly empty with non-inf/+inf values that will cause subsequence intersects to erroneously return valid values.
		if (this.isEmpty()) this.makeEmpty();
		return this;
	}

	public function union(box:Box3):Box3 {
		this.min.min(box.min);
		this.max.max(box.max);
		return this;
	}

	public function applyMatrix4(matrix:Dynamic):Box3 {
		// transform of empty box is an empty box.
		if (this.isEmpty()) return this;

		// NOTE: I am using a binary pattern to specify all 2^3 combinations below
		_points[0].set(this.min.x, this.min.y, this.min.z).applyMatrix4(matrix); // 000
		_points[1].set(this.min.x, this.min.y, this.max.z).applyMatrix4(matrix); // 001
		_points[2].set(this.min.x, this.max.y, this.min.z).applyMatrix4(matrix); // 010
		_points[3].set(this.min.x, this.max.y, this.max.z).applyMatrix4(matrix); // 011
		_points[4].set(this.max.x, this.min.y, this.min.z).applyMatrix4(matrix); // 100
		_points[5].set(this.max.x, this.min.y, this.max.z).applyMatrix4(matrix); // 101
		_points[6].set(this.max.x, this.max.y, this.min.z).applyMatrix4(matrix); // 110
		_points[7].set(this.max.x, this.max.y, this.max.z).applyMatrix4(matrix); // 111

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

// ... (static variables and helper functions) ...

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

// triangle centered vertices
var _v0:Vector3 = new Vector3();
var _v1:Vector3 = new Vector3();
var _v2:Vector3 = new Vector3();

// triangle edge vectors
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
			// project the aabb onto the separating axis
			var r = extents.x * Math.abs(_testAxis.x) + extents.y * Math.abs(_testAxis.y) + extents.z * Math.abs(_testAxis.z);
			// project all 3 vertices of the triangle onto the separating axis
			var p0 = v0.dot(_testAxis);
			var p1 = v1.dot(_testAxis);
			var p2 = v2.dot(_testAxis);
			// actual test, basically see if either of the most extreme of the triangle points intersects r
			if (Math.max(-Math.max(p0, p1, p2), Math.min(p0, p1, p2)) > r) {
				// points of the projected triangle are outside the projected half-length of the aabb
				// the axis is separating and we can exit
				return false;
			}
		}
	}
	return true;
}