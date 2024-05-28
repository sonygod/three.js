import js.Box3;
import js.Vector3;

class Sphere {
    public var isSphere:Bool = true;
    public var center:Vector3;
    public var radius:Float;

    public function new(center:Vector3 = new Vector3(), radius:Float = -1) {
        this.center = center;
        this.radius = radius;
    }

    public function set($:Vector3, radius:Float):Sphere {
        this.center.copy($);
        this.radius = radius;
        return this;
    }

    public function setFromPoints(points:Array<Vector3>, optionalCenter:Vector3 = null):Sphere {
        if (optionalCenter != null) {
            this.center.copy(optionalCenter);
        } else {
            var box = new Box3();
            box.setFromPoints(points);
            box.getCenter(this.center);
        }

        var maxRadiusSq = 0.0;
        for (point in points) {
            maxRadiusSq = Math.max(maxRadiusSq, this.center.distanceToSquared(point));
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
        return this.radius < 0;
    }

    public function makeEmpty():Sphere {
        this.center.set(0, 0, 0);
        this.radius = -1;
        return this;
    }

    public function containsPoint(point:Vector3):Bool {
        return point.distanceToSquared(this.center) <= (this.radius * this.radius);
    }

    public function distanceToPoint(point:Vector3):Float {
        return point.distanceTo(this.center) - this.radius;
    }

    public function intersectsSphere(sphere:Sphere):Bool {
        var radiusSum = this.radius + sphere.radius;
        return sphere.center.distanceToSquared(this.center) <= (radiusSum * radiusSum);
    }

    public function intersectsBox(box:Box3):Bool {
        return box.intersectsSphere(this);
    }

    public function intersectsPlane(plane:Plane):Bool {
        return Math.abs(plane.distanceToPoint(this.center)) <= this.radius;
    }

    public function clampPoint(point:Vector3, target:Vector3):Vector3 {
        var deltaLengthSq = this.center.distanceToSquared(point);
        target.copy(point);
        if (deltaLengthSq > (this.radius * this.radius)) {
            target.sub(this.center);
            target.normalize();
            target.multiplyScalar(this.radius);
            target.add(this.center);
        }
        return target;
    }

    public function getBoundingBox(target:Box3):Box3 {
        if (this.isEmpty()) {
            target.makeEmpty();
            return target;
        }
        target.set(this.center, this.center);
        target.expandByScalar(this.radius);
        return target;
    }

    public function applyMatrix4(matrix:Matrix4):Sphere {
        this.center.applyMatrix4(matrix);
        this.radius = this.radius * matrix.getMaxScaleOnAxis();
        return this;
    }

    public function translate(offset:Vector3):Sphere {
        this.center.add(offset);
        return this;
    }

    public function expandByPoint(point:Vector3):Sphere {
        if (this.isEmpty()) {
            this.center.copy(point);
            this.radius = 0;
            return this;
        }

        var v1 = point.subtract(this.center);
        var lengthSq = v1.lengthSquared();
        if (lengthSq > (this.radius * this.radius)) {
            var length = Math.sqrt(lengthSq);
            var delta = (length - this.radius) * 0.5;
            this.center.addScaledVector(v1, delta / length);
            this.radius += delta;
        }
        return this;
    }

    public function union(sphere:Sphere):Sphere {
        if (sphere.isEmpty()) {
            return this;
        }
        if (this.isEmpty()) {
            this.copy(sphere);
            return this;
        }
        if (this.center.equals(sphere.center)) {
            this.radius = Math.max(this.radius, sphere.radius);
        } else {
            var v2 = sphere.center.subtract(this.center);
            v2.setLength(sphere.radius);
            this.expandByPoint(v2.add(sphere.center));
            this.expandByPoint(v2.subtract(sphere.center));
        }
        return this;
    }

    public function equals(sphere:Sphere):Bool {
        return sphere.center.equals(this.center) && (sphere.radius == this.radius);
    }

    public function clone():Sphere {
        return new Sphere().copy(this);
    }
}