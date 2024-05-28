package math;

import js.Browser.window;

class Box3 {
	public var isBox3:Bool;
	public var min:Vector3;
	public var max:Vector3;

	public function new(min:Vector3 = Vector3.POSITIVE_INFINITY, max:Vector3 = Vector3.NEGATIVE_INFINITY) {
		this.isBox3 = true;
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
			expandByPoint(Vector3.fromArray(array, i));
			i += 3;
		}
		return this;
	}

	public function setFromBufferAttribute(attribute:BufferAttribute):Box3 {
		makeEmpty();
		var i = 0;
		while (i < attribute.count) {
			expandByPoint(Vector3.fromBufferAttribute(attribute, i));
			i++;
		}
		return this;
	}

	public function setFromPoints(points:Array<Vector3>):Box3 {
		makeEmpty();
		var i = 0;
		while (i < points.length) {
			expandByPoint(points[i]);
			i++;
		}
		return this;
	}

	public function setFromCenterAndSize(center:Vector3, size:Vector3):Box3 {
		var halfSize = size.clone().multiplyScalar(0.5);
		min.copy(center).sub(halfSize);
		max.copy(center).add(halfSize);
		return this;
	}

	public function setFromObject(object:Object3D, precise:Bool = false):Box3 {
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
		min.x = min.y = min.z = window.Infinity;
		max.x = max.y = max.z = -window.Infinity;
		return this;
	}

	public function isEmpty():Bool {
		// this is a more robust check for empty than ( volume <= 0 ) because volume can get positive with two negative axes
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

	public function expandByObject(object:Object3D, precise:Bool = false):Box3 {
		// Computes the world-axis-aligned bounding box of an object (including its children),
		// accounting for both the object's, and children's, world transforms
		object.updateWorldMatrix(false, false);

		var geometry = object.geometry;
		if (geometry != null) {
			var positionAttribute = geometry.getAttribute("position");

			// precise AABB computation based on vertex data requires at least a position attribute.
			// instancing isn't supported so far and uses the normal (conservative) code path.
			if (precise && positionAttribute != null && !object.isInstancedMesh) {
				var i = 0;
				while (i < positionAttribute.count) {
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
				if (object.boundingBox != null) {
					// object-level bounding box
					if (object.boundingBox == null) {
						object.computeBoundingBox();
					}
					_box.copy(object.boundingBox);
				} else {
					// geometry-level bounding box
					if (geometry.boundingBox == null) {
						geometry.computeBoundingBox();
					}
					_box.copy(geometry.boundingBox);
				}
				_box.applyMatrix4(object.matrixWorld);
				union(_box);
			}
		}

		var children = object.children;
		var i = 0;
		while (i < children.length) {
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
		// This can potentially have a divide by zero if the box
		// has a size dimension of 0.
		return target.set((point.x - min.x) / (max.x - min.x), (point.y - min.y) / (max.y - min.y), (point.z - min.z) / (max.z - min.z));
	}

	public function intersectsBox(box:Box3):Bool {
		// using 6 splitting planes to rule out intersections.
		return (box.max.x < min.x || box.min.x > max.x) || (box.max.y < min.y || box.min.y > max.y) || (box.max.z < min.z || box.min.z > max.z) ? false : true;
	}

	public function intersectsSphere(sphere:Sphere):Bool {
		// Find the point on the AABB closest to the sphere center.
		clampPoint(sphere.center, _vector);

		// If that point is inside the sphere, the AABB and sphere intersect.
		return _vector.distanceToSquared(sphere.center) <= (sphere.radius * sphere.radius);
	}

	public function intersectsPlane(plane:Plane):Bool {
		// We compute the minimum and maximum dot product values. If those values
		// are on the same side (back or front) of the plane, then there is no intersection.
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

	public function intersectsTriangle(triangle:Triangle):Bool {
		if (isEmpty()) {
			return false;
		}

		// compute box center and extents
		getCenter(_center);
		_extents.subVectors(max, _center);

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
		return target.copy(point).clamp(min, max);
	}

	public function distanceToPoint(point:Vector3):Float {
		return clampPoint(point, _vector).distanceTo(point);
	}

	public function getBoundingSphere(target:Sphere):Sphere {
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

		// ensure that if there is no overlap, the result is fully empty, not slightly empty with non-inf/+inf values that will cause subsequence intersects to erroneously return valid values.
		if (isEmpty()) makeEmpty();

		return this;
	}

	public function union(box:Box3):Box3 {
		min.min(box.min);
		max.max(box.max);
		return this;
	}

	public function applyMatrix4(matrix:Matrix4):Box3 {
		// transform of empty box is an empty box.
		if (isEmpty()) return this;

		// NOTE: I am using a binary pattern to specify all 2^3 combinations below
		_points[0].set(min.x, min.y, min.z).applyMatrix4(matrix); // 000
		_points[1].set(min.x, min.y, max.z).applyMatrix4(matrix); // 001
		_points[2].set(min.x, max.y, min.z).applyMatrix4(matrix); // 010
		_points[3].set(min.x, max.y, max.z).applyMatrix4(matrix); // 011
		_points[4].set(max.x, min.y, min.z).applyMatrix4(matrix); // 100
		_points[5].set(max.x, min.y, max.z).applyMatrix4(matrix); // 101
		_points[6].set(max.x, max.y, min.z).applyMatrix4(matrix); // 110
		_points[7].set(max.x, max.y, max.z).applyMatrix4(matrix); // 111

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

	static var _points:Array<Vector3> = [
		new Vector3(),
		new Vector3(),
		new Vector3(),
		new Vector3(),
		new Vector3(),
		new Vector3(),
		new Vector3(),
		new Vector3()
	];

	static var _vector:Vector3 = new Vector3();
	static var _box:Box3 = new Box3();

	// triangle centered vertices
	static var _v0:Vector3 = new Vector3();
	static var _v1:Vector3 = new Vector3();
	static var _v2:Vector3 = new Vector3();

	// triangle edge vectors
	static var _f0:Vector3 = new Vector3();
	static var _f1:Vector3 = new Vector3();
	static var _f2:Vector3 = new Vector3();

	static var _center:Vector3 = new Vector3();
	static var _extents:Vector3 = new Vector3();
	static var _triangleNormal:Vector3 = new Vector3();
	static var _testAxis:Vector3 = new Vector3();

	static function satForAxes(axes:Array<Float>, v0:Vector3, v1:Vector3, v2:Vector3, extents:Vector3):Bool {
		var i = 0;
		while (i < axes.length) {
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
			i += 3;
		}
		return true;
	}
}