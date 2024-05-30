package three.js.math;

import three.js.math.Box3;
import three.js.math.Line3;
import three.js.math.Plane;
import three.js.math.Sphere;
import three.js.math.Triangle;
import three.js.math.Vector3;
import three.js.Layers;
import three.js.math.Capsule;

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
        var halfsize:Vector3 = _v2.copy(this.box.max).sub(this.box.min).multiplyScalar(0.5);
        for (x in 0...2) {
            for (y in 0...2) {
                for (z in 0...2) {
                    var box:Box3 = new Box3();
                    var v:Vector3 = _v1.set(x, y, z);
                    box.min.copy(this.box.min).add(v.multiply(halfsize));
                    box.max.copy(box.min).add(halfsize);
                    subTrees.push(new Octree(box));
                }
            }
        }
        while (triangle = this.triangles.pop()) {
            for (i in 0...subTrees.length) {
                if (subTrees[i].box.intersectsTriangle(triangle)) {
                    subTrees[i].triangles.push(triangle);
                }
            }
        }
        for (i in 0...subTrees.length) {
            if (subTrees[i].triangles.length > 8 && level < 16) {
                subTrees[i].split(level + 1);
            }
            if (subTrees[i].triangles.length != 0) {
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
            var subTree:Octree = this.subTrees[i];
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

    public function triangleCapsuleIntersect(capsule:Capsule, triangle:Triangle):{ normal:Vector3, point:Vector3, depth:Float } {
        triangle.getPlane(_plane);
        var d1:Float = _plane.distanceToPoint(capsule.start) - capsule.radius;
        var d2:Float = _plane.distanceToPoint(capsule.end) - capsule.radius;
        if ((d1 > 0 && d2 > 0) || (d1 < -capsule.radius && d2 < -capsule.radius)) return null;
        var delta:Float = Math.abs(d1) / (Math.abs(d1) + Math.abs(d2));
        var intersectPoint:Vector3 = _v1.copy(capsule.start).lerp(capsule.end, delta);
        if (triangle.containsPoint(intersectPoint)) {
            return { normal:_plane.normal.clone(), point: intersectPoint.clone(), depth:Math.abs(Math.min(d1, d2)) };
        }
        var r2:Float = capsule.radius * capsule.radius;
        var line1:Line3 = _line1.set(capsule.start, capsule.end);
        var lines:Array<Array<Vector3>> = [
            [triangle.a, triangle.b],
            [triangle.b, triangle.c],
            [triangle.c, triangle.a]
        ];
        for (i in 0...lines.length) {
            var line2:Line3 = _line2.set(lines[i][0], lines[i][1]);
            lineToLineClosestPoints(line1, line2, _point1, _point2);
            if (_point1.distanceToSquared(_point2) < r2) {
                return {
                    normal:_point1.clone().sub(_point2).normalize(),
                    point:_point2.clone(),
                    depth:capsule.radius - _point1.distanceTo(_point2)
                };
            }
        }
        return null;
    }

    public function triangleSphereIntersect(sphere:Sphere, triangle:Triangle):{ normal:Vector3, point:Vector3, depth:Float } {
        triangle.getPlane(_plane);
        if (!sphere.intersectsPlane(_plane)) return null;
        var depth:Float = Math.abs(_plane.distanceToSphere(sphere));
        var r2:Float = sphere.radius * sphere.radius - depth * depth;
        var plainPoint:Vector3 = _plane.projectPoint(sphere.center, _v1);
        if (triangle.containsPoint(sphere.center)) {
            return { normal:_plane.normal.clone(), point:plainPoint.clone(), depth:Math.abs(_plane.distanceToSphere(sphere)) };
        }
        var lines:Array<Array<Vector3>> = [
            [triangle.a, triangle.b],
            [triangle.b, triangle.c],
            [triangle.c, triangle.a]
        ];
        for (i in 0...lines.length) {
            _line1.set(lines[i][0], lines[i][1]);
            _line1.closestPointToPoint(plainPoint, true, _v2);
            var d:Float = _v2.distanceToSquared(sphere.center);
            if (d < r2) {
                return {
                    normal:sphere.center.clone().sub(_v2).normalize(),
                    point:_v2.clone(),
                    depth:sphere.radius - Math.sqrt(d)
                };
            }
        }
        return null;
    }

    public function getSphereTriangles(sphere:Sphere, triangles:Array<Triangle>):Array<Triangle> {
        for (i in 0...this.subTrees.length) {
            var subTree:Octree = this.subTrees[i];
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
            var subTree:Octree = this.subTrees[i];
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

    public function sphereIntersect(sphere:Sphere):{ normal:Vector3, depth:Float } {
        _sphere.copy(sphere);
        var triangles:Array<Triangle> = [];
        var result:Object, hit:Bool = false;
        this.getSphereTriangles(_sphere, triangles);
        for (i in 0...triangles.length) {
            if (result = this.triangleSphereIntersect(_sphere, triangles[i])) {
                hit = true;
                _sphere.center.add(result.normal.multiplyScalar(result.depth));
            }
        }
        if (hit) {
            var collisionVector:Vector3 = _sphere.center.clone().sub(sphere.center);
            var depth:Float = collisionVector.length();
            return { normal:collisionVector.normalize(), depth:depth };
        }
        return null;
    }

    public function capsuleIntersect(capsule:Capsule):{ normal:Vector3, depth:Float } {
        _capsule.copy(capsule);
        var triangles:Array<Triangle> = [];
        var result:Object, hit:Bool = false;
        this.getCapsuleTriangles(_capsule, triangles);
        for (i in 0...triangles.length) {
            if (result = this.triangleCapsuleIntersect(_capsule, triangles[i])) {
                hit = true;
                _capsule.translate(result.normal.multiplyScalar(result.depth));
            }
        }
        if (hit) {
            var collisionVector:Vector3 = _capsule.getCenter(new Vector3()).sub(capsule.getCenter(_v1));
            var depth:Float = collisionVector.length();
            return { normal:collisionVector.normalize(), depth:depth };
        }
        return null;
    }

    public function rayIntersect(ray:Ray):{ distance:Float, triangle:Triangle, position:Vector3 } {
        if (ray.direction.length() == 0) return null;
        var triangles:Array<Triangle> = [];
        var triangle:Triangle, position:Vector3, distance:Float = 1e100;
        this.getRayTriangles(ray, triangles);
        for (i in 0...triangles.length) {
            var result:Object = ray.intersectTriangle(triangles[i].a, triangles[i].b, triangles[i].c, true, _v1);
            if (result) {
                var newdistance:Float = result.sub(ray.origin).length();
                if (distance > newdistance) {
                    position = result.clone().add(ray.origin);
                    distance = newdistance;
                    triangle = triangles[i];
                }
            }
        }
        return distance < 1e100 ? { distance:distance, triangle:triangle, position:position } : null;
    }

    public function fromGraphNode(group:Object):Octree {
        group.updateWorldMatrix(true, true);
        group.traverse((obj:Object) -> {
            if (obj.isMesh) {
                if (this.layers.test(obj.layers)) {
                    var geometry:Object, isTemp:Bool = false;
                    if (obj.geometry.index != null) {
                        isTemp = true;
                        geometry = obj.geometry.toNonIndexed();
                    } else {
                        geometry = obj.geometry;
                    }
                    var positionAttribute:Object = geometry.getAttribute('position');
                    for (i in 0...positionAttribute.count) {
                        var v1:Vector3 = new Vector3().fromBufferAttribute(positionAttribute, i);
                        var v2:Vector3 = new Vector3().fromBufferAttribute(positionAttribute, i + 1);
                        var v3:Vector3 = new Vector3().fromBufferAttribute(positionAttribute, i + 2);
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
}