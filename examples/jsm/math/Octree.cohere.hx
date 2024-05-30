import js.three.Box3;
import js.three.Line3;
import js.three.Plane;
import js.three.Sphere;
import js.three.Triangle;
import js.three.Vector3;
import js.three.Layers;
import js.three.Capsule;

class Octree {

	public var box:Box3;
	public var bounds:Box3;
	public var subTrees:Array<Octree>;
	public var triangles:Array<Triangle>;
	public var layers:Layers;

	public function new(box:Box3) {
		this.box = box;
		this.bounds = new Box3();
		this.subTrees = [];
		this.triangles = [];
		this.layers = new Layers();
	}

	public function addTriangle(triangle:Triangle):Octree {
		bounds.min.x = min(bounds.min.x, triangle.a.x, triangle.b.x, triangle.c.x);
		bounds.min.y = min(bounds.min.y, triangle.a.y, triangle.b.y, triangle.c.y);
		bounds.min.z = min(bounds.min.z, triangle.a.z, triangle.b.z, triangle.c.z);
		bounds.max.x = max(bounds.max.x, triangle.a.x, triangle.b.x, triangle.c.x);
		bounds.max.y = max(bounds.max.y, triangle.a.y, triangle.b.y, triangle.c.y);
		bounds.max.z = max(bounds.max.z, triangle.a.z, triangle.b.z, triangle.c.z);
		triangles.push(triangle);
		return this;
	}

	public function calcBox():Octree {
		box = bounds.clone();
		box.min.x -= 0.01;
		box.min.y -= 0.01;
		box.min.z -= 0.01;
		return this;
	}

	public function split(level:Int):Octree {
		if (box == null) return;
		var subTrees = [];
		var halfsize = _v2.copy(box.max).sub(box.min).multiplyScalar(0.5);
		for (x in 0...2) {
			for (y in 0...2) {
				for (z in 0...2) {
					var box = new Box3();
					var v = _v1.set(x, y, z);
					box.min.copy(this.box.min).add(v.multiply(halfsize));
					box.max.copy(box.min).add(halfsize);
					subTrees.push(new Octree(box));
				}
			}
		}
		var triangle:Triangle;
		while (triangle = triangles.pop()) {
			for (i in 0...subTrees.length) {
				if (subTrees[i].box.intersectsTriangle(triangle)) {
					subTrees[i].triangles.push(triangle);
				}
			}
		}
		for (i in 0...subTrees.length) {
			var len = subTrees[i].triangles.length;
			if (len > 8 && level < 16) {
				subTrees[i].split(level + 1);
			}
			if (len != 0) {
				this.subTrees.push(subTrees[i]);
			}
		}
		return this;
	}

	public function build():Octree {
		calcBox();
		split(0);
		return this;
	}

	public function getRayTriangles(ray:Ray, triangles:Array<Triangle>):Array<Triangle> {
		for (i in 0...subTrees.length) {
			var subTree = subTrees[i];
			if (!ray.intersectsBox(subTree.box)) continue;
			if (subTree.triangles.length > 0) {
				for (j in 0...subTree.triangles.length) {
					if (triangles.indexOf(subTree.triangles[j]) == -1) triangles.push(subTree.triangles[j]);
				}
			} else {
				subTree.getRayTriangles(ray, triangles);
			}
		}
		return triangles;
	}

	public function triangleCapsuleIntersect(capsule:Capsule, triangle:Triangle):Null<Map> {
		var _plane = new Plane();
		triangle.getPlane(_plane);
		var d1 = _plane.distanceToPoint(capsule.start) - capsule.radius;
		var d2 = _plane.distanceToPoint(capsule.end) - capsule.radius;
		if ((d1 > 0 && d2 > 0) || (d1 < -capsule.radius && d2 < -capsule.radius)) {
			return null;
		}
		var delta = abs(d1) / (abs(d1) + abs(d2));
		var intersectPoint = _v1.copy(capsule.start).lerp(capsule.end, delta);
		if (triangle.containsPoint(intersectPoint)) {
			return { normal: _plane.normal.clone(), point: intersectPoint.clone(), depth: abs(min(d1, d2)) };
		}
		var r2 = capsule.radius * capsule.radius;
		var line1 = _line1.set(capsule.start, capsule.end);
		var lines = [
			[ triangle.a, triangle.b ],
			[ triangle.b, triangle.c ],
			[ triangle.c, triangle.a ]
		];
		for (i in 0...lines.length) {
			var line2 = _line2.set(lines[i][0], lines[i][1]);
			var _point1 = new Vector3();
			var _point2 = new Vector3();
			lineToLineClosestPoints(line1, line2, _point1, _point2);
			if (_point1.distanceToSquared(_point2) < r2) {
				return {
					normal: _point1.clone().sub(_point2).normalize(),
					point: _point2.clone(),
					depth: capsule.radius - _point1.distanceTo(_point2)
				};
			}
		}
		return null;
	}

	public function triangleSphereIntersect(sphere:Sphere, triangle:Triangle):Null<Map> {
		var _plane = new Plane();
		triangle.getPlane(_plane);
		if (!sphere.intersectsPlane(_plane)) return null;
		var depth = abs(_plane.distanceToSphere(sphere));
		var r2 = sphere.radius * sphere.radius - depth * depth;
		var plainPoint = _plane.projectPoint(sphere.center, _v1);
		if (triangle.containsPoint(sphere.center)) {
			return { normal: _plane.normal.clone(), point: plainPoint.clone(), depth: abs(_plane.distanceToSphere(sphere)) };
		}
		var lines = [
			[ triangle.a, triangle.b ],
			[ triangle.b, triangle.c ],
			[ triangle.c, triangle.a ]
		];
		for (i in 0...lines.length) {
			_line1.set(lines[i][0], lines[i][1]);
			_line1.closestPointToPoint(plainPoint, true, _v2);
			var d = _v2.distanceToSquared(sphere.center);
			if (d < r2) {
				return { normal: sphere.center.clone().sub(_v2).normalize(), point: _v2.clone(), depth: sphere.radius - sqrt(d) };
			}
		}
		return null;
	}

	public function getSphereTriangles(sphere:Sphere, triangles:Array<Triangle>):Array<Triangle> {
		for (i in 0...subTrees.length) {
			var subTree = subTrees[i];
			if (!sphere.intersectsBox(subTree.box)) continue;
			if (subTree.triangles.length > 0) {
				for (j in 0...subTree.triangles.length) {
					if (triangles.indexOf(subTree.triangles[j]) == -1) triangles.push(subTree.triangles[j]);
				}
			} else {
				subTree.getSphereTriangles(sphere, triangles);
			}
		}
		return triangles;
	}

	public function getCapsuleTriangles(capsule:Capsule, triangles:Array<Triangle>):Array<Triangle> {
		for (i in 0...subTrees.length) {
			var subTree = subTrees[i];
			if (!capsule.intersectsBox(subTree.box)) continue;
			if (subTree.triangles.length > 0) {
				for (j in 0...subTree.triangles.length) {
					if (triangles.indexOf(subTree.triangles[j]) == -1) triangles.push(subTree.triangles[j]);
				}
			} else {
				subTree.getCapsuleTriangles(capsule, triangles);
			}
		}
		return triangles;
	}

	public function sphereIntersect(sphere:Sphere):Null<Map> {
		var _sphere = sphere.clone();
		var triangles = [];
		var result:Null<Map>;
		var hit = false;
		getSphereTriangles(sphere, triangles);
		for (i in 0...triangles.length) {
			if (result = triangleSphereIntersect(_sphere, triangles[i])) {
				hit = true;
				_sphere.center.add(result.normal.multiplyScalar(result.depth));
			}
		}
		if (hit) {
			var collisionVector = _sphere.center.clone().sub(sphere.center);
			var depth = collisionVector.length();
			return { normal: collisionVector.normalize(), depth: depth };
		}
		return null;
	}

	public function capsuleIntersect(capsule:Capsule):Null<Map> {
		var _capsule = capsule.clone();
		var triangles = [];
		var result:Null<Map>;
		var hit = false;
		getCapsuleTriangles(_capsule, triangles);
		for (i in 0...triangles.length) {
			if (result = triangleCapsuleIntersect(_capsule, triangles[i])) {
				hit = true;
				_capsule.translate(result.normal.multiplyScalar(result.depth));
			}
		}
		if (hit) {
			var collisionVector = _capsule.getCenter(new Vector3()).sub(capsule.getCenter(_v1));
			var depth = collisionVector.length();
			return { normal: collisionVector.normalize(), depth: depth };
		}
		return null;
	}

	public function rayIntersect(ray:Ray):Null<Map> {
		if (ray.direction.length() == 0) return null;
		var triangles = [];
		var triangle:Triangle;
		var position:Vector3;
		var distance = 1e100;
		getRayTriangles(ray, triangles);
		for (i in 0...triangles.length) {
			var result = ray.intersectTriangle(triangles[i].a, triangles[i].b, triangles[i].c, true, _v1);
			if (result) {
				var newdistance = result.sub(ray.origin).length();
				if (distance > newdistance) {
					position = result.clone().add(ray.origin);
					distance = newdistance;
					triangle = triangles[i];
				}
			}
		}
		return distance < 1e100 ? { distance: distance, triangle: triangle, position: position } : null;
	}

	public function fromGraphNode(group:GraphNode):Octree {
		group.updateWorldMatrix(true, true);
		group.traverse(function (obj) {
			if (obj.isMesh) {
				if (layers.test(obj.layers)) {
					var geometry:Geometry;
					var isTemp = false;
					if (obj.geometry.index != null) {
						isTemp = true;
						geometry = obj.geometry.toNonIndexed();
					} else {
						geometry = obj.geometry;
					}
					var positionAttribute = geometry.getAttribute('position');
					for (i in 0...positionAttribute.count) {
						var v1 = new Vector3().fromBufferAttribute(positionAttribute, i);
						var v2 = new Vector3().fromBufferAttribute(positionAttribute, i + 1);
						var v3 = new Vector3().fromBufferAttribute(positionAttribute, i + 2);
						v1.applyMatrix4(obj.matrixWorld);
						v2.applyMatrix4(obj.matrixWorld);
						v3.applyMatrix4(obj.matrixWorld);
						addTriangle(new Triangle(v1, v2, v3));
					}
					if (isTemp) {
						geometry.dispose();
					}
				}
			}
		});
		build();
		return this;
	}

	public function clear():Octree {
		box = null;
		bounds.makeEmpty();
		subTrees.length = 0;
		triangles.length = 0;
		return this;
	}

}

function lineToLineClosestPoints(line1:Line3, line2:Line3, target1:Vector3 = null, target2:Vector3 = null):Void {
	var r = _temp1.copy(line1.end).sub(line1.start);
	var s = _temp2.copy(line2.end).sub(line2.start);
	var w = _temp3.copy(line2.start).sub(line1.start);
	var a = r.dot(s);
	var b = r.dot(r);
	var c = s.dot(s);
	var d = s.dot(w);
	var e = r.dot(w);
	var t1:Float, t2:Float;
	var divisor = b * c - a * a;
	if (abs(divisor) < EPS) {
		var d1 = -d / c;
		var d2 = (a - d) / c;
		if (abs(d1 - 0.5) < abs(d2 - 0.5)) {
			t1 = 0;
			t2 = d1;
		} else {
			t1 = 1;
			t2 = d2;
		}
	} else {
		t1 = (d * a + e * c) / divisor;
		t2 = (t1 * a - d) / c;
	}
	t2 = max(0, min(1, t2));
	t1 = max(0, min(1, t1));
	if (target1) {
		target1.copy(r).multiplyScalar(t1).add(line1.start);
	}
	if (target2) {
		target2.copy(s).multiplyScalar(t2).add(line2.start);
	}
}

export { Octree };