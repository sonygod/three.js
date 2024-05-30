import three.Box3;
import three.Line3;
import three.Plane;
import three.Sphere;
import three.Triangle;
import three.Vector3;
import three.Layers;
import Capsule from '../math/Capsule.js';

class Octree {

    static var _v1 = new Vector3();
    static var _v2 = new Vector3();
    static var _point1 = new Vector3();
    static var _point2 = new Vector3();
    static var _plane = new Plane();
    static var _line1 = new Line3();
    static var _line2 = new Line3();
    static var _sphere = new Sphere();
    static var _capsule = new Capsule();

    static var _temp1 = new Vector3();
    static var _temp2 = new Vector3();
    static var _temp3 = new Vector3();
    static var EPS = 1e-10;

    var box:Box3;
    var bounds:Box3;
    var subTrees:Array<Octree>;
    var triangles:Array<Triangle>;
    var layers:Layers;

    public function new(box:Box3) {
        this.box = box;
        this.bounds = new Box3();
        this.subTrees = [];
        this.triangles = [];
        this.layers = new Layers();
    }

    public function addTriangle(triangle:Triangle):Octree {
        this.bounds.min.x = Math.min(this.bounds.min.x, triangle.a.x, triangle.b.x, triangle.c.x);
        this.bounds.min.y = Math.min(this.bounds.min.y, triangle.a.y, triangle.b.y, triangle.c.y);
        this.bounds.min.z = Math.min(this.bounds.min.z, triangle.a.z, triangle.b.z, triangle.c.z);
        this.bounds.max.x = Math.max(this.bounds.max.x, triangle.a.x, triangle.b.x, triangle.c.x);
        this.bounds.max.y = Math.max(this.bounds.max.y, triangle.a.y, triangle.b.y, triangle.c.y);
        this.bounds.max.z = Math.max(this.bounds.max.z, triangle.a.z, triangle.b.z, triangle.c.z);
        this.triangles.push(triangle);
        return this;
    }

    public function calcBox():Octree {
        this.box = this.bounds.clone();
        this.box.min.x -= 0.01;
        this.box.min.y -= 0.01;
        this.box.min.z -= 0.01;
        return this;
    }

    public function split(level:Int):Octree {
        if (this.box == null) return this;
        var subTrees:Array<Octree> = [];
        var halfsize = _v2.copy(this.box.max).sub(this.box.min).multiplyScalar(0.5);
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
        while (triangle = this.triangles.pop()) {
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
        this.calcBox();
        this.split(0);
        return this;
    }

    public function getRayTriangles(ray:Ray, triangles:Array<Triangle>):Array<Triangle> {
        for (i in 0...this.subTrees.length) {
            var subTree = this.subTrees[i];
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

    public function triangleCapsuleIntersect(capsule:Capsule, triangle:Triangle):Dynamic {
        triangle.getPlane(_plane);
        var d1 = _plane.distanceToPoint(capsule.start) - capsule.radius;
        var d2 = _plane.distanceToPoint(capsule.end) - capsule.radius;
        if ((d1 > 0 && d2 > 0) || (d1 < -capsule.radius && d2 < -capsule.radius)) {
            return false;
        }
        var delta = Math.abs(d1 / (Math.abs(d1) + Math.abs(d2)));
        var intersectPoint = _v1.copy(capsule.start).lerp(capsule.end, delta);
        if (triangle.containsPoint(intersectPoint)) {
            return {normal: _plane.normal.clone(), point: intersectPoint.clone(), depth: Math.abs(Math.min(d1, d2))};
        }
        var r2 = capsule.radius * capsule.radius;
        var line1 = _line1.set(capsule.start, capsule.end);
        var lines = [[triangle.a, triangle.b], [triangle.b, triangle.c], [triangle.c, triangle.a]];
        for (i in 0...lines.length) {
            var line2 = _line2.set(lines[i][0], lines[i][1]);
            lineToLineClosestPoints(line1, line2, _point1, _point2);
            if (_point1.distanceToSquared(_point2) < r2) {
                return {normal: _point1.clone().sub(_point2).normalize(), point: _point2.clone(), depth: capsule.radius - _point1.distanceTo(_point2)};
            }
        }
        return false;
    }

    public function triangleSphereIntersect(sphere:Sphere, triangle:Triangle):Dynamic {
        triangle.getPlane(_plane);
        if (!sphere.intersectsPlane(_plane)) return false;
        var depth = Math.abs(_plane.distanceToSphere(sphere));
        var r2 = sphere.radius * sphere.radius - depth * depth;
        var plainPoint = _plane.projectPoint(sphere.center, _v1);
        if (triangle.containsPoint(sphere.center)) {
            return {normal: _plane.normal.clone(), point: plainPoint.clone(), depth: Math.abs(_plane.distanceToSphere(sphere))};
        }
        var lines = [[triangle.a, triangle.b], [triangle.b, triangle.c], [triangle.c, triangle.a]];
        for (i in 0...lines.length) {
            _line1.set(lines[i][0], lines[i][1]);
            _line1.closestPointToPoint(plainPoint, true, _v2);
            var d = _v2.distanceToSquared(sphere.center);
            if (d < r2) {
                return {normal: sphere.center.clone().sub(_v2).normalize(), point: _v2.clone(), depth: sphere.radius - Math.sqrt(d)};
            }
        }
        return false;
    }

    public function getSphereTriangles(sphere:Sphere, triangles:Array<Triangle>):Array<Triangle> {
        for (i in 0...this.subTrees.length) {
            var subTree = this.subTrees[i];
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
        for (i in 0...this.subTrees.length) {
            var subTree = this.subTrees[i];
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

    public function sphereIntersect(sphere:Sphere):Dynamic {
        _sphere.copy(sphere);
        var triangles:Array<Triangle> = [];
        var result:Dynamic;
        var hit = false;
        this.getSphereTriangles(sphere, triangles);
        for (i in 0...triangles.length) {
            if (result = this.triangleSphereIntersect(_sphere, triangles[i])) {
                hit = true;
                _sphere.center.add(result.normal.multiplyScalar(result.depth));
            }
        }
        if (hit) {
            var collisionVector = _sphere.center.clone().sub(sphere.center);
            var depth = collisionVector.length();
            return {normal: collisionVector.normalize(), depth: depth};
        }
        return false;
    }

    public function capsuleIntersect(capsule:Capsule):Dynamic {
        _capsule.copy(capsule);
        var triangles:Array<Triangle> = [];
        var result:Dynamic;
        var hit = false;
        this.getCapsuleTriangles(_capsule, triangles);
        for (i in 0...triangles.length) {
            if (result = this.triangleCapsuleIntersect(_capsule, triangles[i])) {
                hit = true;
                _capsule.translate(result.normal.multiplyScalar(result.depth));
            }
        }
        if (hit) {
            var collisionVector = _capsule.getCenter(new Vector3()).sub(_capsule.getCenter(new Vector3()));
            var depth = collisionVector.length();
            return {normal: collisionVector.normalize(), depth: depth};
        }
        return false;
    }

    public function rayIntersect(ray:Ray):Dynamic {
        if (ray.direction.length() == 0) return false;
        var triangles:Array<Triangle> = [];
        var triangle:Triangle;
        var position:Vector3;
        var distance = 1e100;
        this.getRayTriangles(ray, triangles);
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
        return distance < 1e100 ? {distance: distance, triangle: triangle, position: position} : false;
    }

    public function fromGraphNode(group:Group):Octree {
        group.updateWorldMatrix(true, true);
        group.traverse((obj) -> {
            if (obj.isMesh == true) {
                if (this.layers.test(obj.layers)) {
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
                        this.addTriangle(new Triangle(v1, v2, v3));
                    }
                    if (isTemp) {
                        geometry.dispose();
                    }
                }
            }
        });
        this.build();
        return this;
    }

    public function clear():Octree {
        this.box = null;
        this.bounds.makeEmpty();
        this.subTrees.length = 0;
        this.triangles.length = 0;
        return this;
    }

    static function lineToLineClosestPoints(line1:Line3, line2:Line3, target1:Vector3, target2:Vector3):Void {
        var r = _temp1.copy(line1.end).sub(line1.start);
        var s = _temp2.copy(line2.end).sub(line2.start);
        var w = _temp3.copy(line2.start).sub(line1.start);
        var a = r.dot(s);
        var b = r.dot(r);
        var c = s.dot(s);
        var d = s.dot(w);
        var e = r.dot(w);
        var t1:Float;
        var t2:Float;
        var divisor = b * c - a * a;
        if (Math.abs(divisor) < EPS) {
            var d1 = -d / c;
            var d2 = (a - d) / c;
            if (Math.abs(d1 - 0.5) < Math.abs(d2 - 0.5)) {
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
        t2 = Math.max(0, Math.min(1, t2));
        t1 = Math.max(0, Math.min(1, t1));
        if (target1) {
            target1.copy(r).multiplyScalar(t1).add(line1.start);
        }
        if (target2) {
            target2.copy(s).multiplyScalar(t2).add(line2.start);
        }
    }

}