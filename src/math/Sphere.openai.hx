package three.math;

import three.math.Box3;
import three.math.Vector3;

class Sphere {
    public var center:Vector3;
    public var radius:Float;
    public var isSphere:Bool;

    public function new(?center:Vector3, ?radius:Float) {
        this.isSphere = true;
        this.center = center != null ? center : new Vector3();
        this.radius = radius != null ? radius : -1;
    }

    public function set(center:Vector3, radius:Float):Sphere {
        this.center.copy(center);
        this.radius = radius;
        return this;
    }

    public function setFromPoints(points:Array<Vector3>, ?optionalCenter:Vector3):Sphere {
        var center:Vector3 = this.center;
        if (optionalCenter != null) {
            center.copy(optionalCenter);
        } else {
            var box:Box3 = new Box3();
            box.setFromPoints(points);
            center.copy(box.getCenter(new Vector3()));
        }
        var maxRadiusSq:Float = 0;
        for (i in 0...points.length) {
            maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(points[i]));
        }
        this.radius = Math.sqrt(maxRadiusSq);
        return this;
    }

    public function copy(sphere:Sphere):Sphere {
        this.center.copy(sphere.center);
        this.radius = sphere.radius;
        return this;
    }

    public function isEmpty():Bool {
        return radius < 0;
    }

    public function makeEmpty():Sphere {
        center.set(0, 0, 0);
        radius = -1;
        return this;
    }

    public function containsPoint(point:Vector3):Bool {
        return point.distanceToSquared(center) <= radius * radius;
    }

    public function distanceToPoint(point:Vector3):Float {
        return point.distanceTo(center) - radius;
    }

    public function intersectsSphere(sphere:Sphere):Bool {
        var radiusSum:Float = radius + sphere.radius;
        return sphere.center.distanceToSquared(center) <= radiusSum * radiusSum;
    }

    public function intersectsBox(box:Box3):Bool {
        return box.intersectsSphere(this);
    }

    public function intersectsPlane(plane:Plane):Bool {
        return Math.abs(plane.distanceToPoint(center)) <= radius;
    }

    public function clampPoint(point:Vector3, target:Vector3):Vector3 {
        var deltaLengthSq:Float = center.distanceToSquared(point);
        target.copy(point);
        if (deltaLengthSq > radius * radius) {
            target.sub(center).normalize();
            target.multiplyScalar(radius).add(center);
        }
        return target;
    }

    public function getBoundingBox(target:Box3):Box3 {
        if (isEmpty()) {
            target.makeEmpty();
            return target;
        }
        target.set(center, center);
        target.expandByScalar(radius);
        return target;
    }

    public function applyMatrix4(matrix:Matrix4):Sphere {
        center.applyMatrix4(matrix);
        radius *= matrix.getMaxScaleOnAxis();
        return this;
    }

    public function translate(offset:Vector3):Sphere {
        center.add(offset);
        return this;
    }

    public function expandByPoint(point:Vector3):Sphere {
        if (isEmpty()) {
            center.copy(point);
            radius = 0;
            return this;
        }
        var v1:Vector3 = new Vector3();
        v1.subVectors(point, center);
        var lengthSq:Float = v1.lengthSq();
        if (lengthSq > radius * radius) {
            var length:Float = Math.sqrt(lengthSq);
            var delta:Float = (length - radius) * 0.5;
            center.addScaledVector(v1, delta / length);
            radius += delta;
        }
        return this;
    }

    public function union(sphere:Sphere):Sphere {
        if (sphere.isEmpty()) {
            return this;
        }
        if (isEmpty()) {
            copy(sphere);
            return this;
        }
        if (center.equals(sphere.center)) {
            radius = Math.max(radius, sphere.radius);
        } else {
            var v2:Vector3 = new Vector3();
            v2.subVectors(sphere.center, center).setLength(sphere.radius);
            expandByPoint(new Vector3().copy(sphere.center).add(v2));
            expandByPoint(new Vector3().copy(sphere.center).sub(v2));
        }
        return this;
    }

    public function equals(sphere:Sphere):Bool {
        return sphere.center.equals(center) && sphere.radius == radius;
    }

    public function clone():Sphere {
        return new Sphere().copy(this);
    }
}