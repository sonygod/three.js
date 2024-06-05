import three.math.Box3;
import three.math.Vector3;

class Sphere {
    public var isSphere:Bool;
    public var center:Vector3;
    public var radius:Float;

    static var _box = new Box3();
    static var _v1 = new Vector3();
    static var _v2 = new Vector3();

    public function new(?center:Vector3 = null, ?radius:Float = -1) {
        this.isSphere = true;
        this.center = center == null ? new Vector3() : center;
        this.radius = radius;
    }

    public function set(center:Vector3, radius:Float):Sphere {
        this.center.copy(center);
        this.radius = radius;
        return this;
    }

    public function setFromPoints(points:Array<Vector3>, ?optionalCenter:Vector3):Sphere {
        var center = this.center;
        
        if (optionalCenter != null) {
            center.copy(optionalCenter);
        } else {
            _box.setFromPoints(points).getCenter(center);
        }

        var maxRadiusSq = 0.0;

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
        return (this.radius < 0);
    }

    public function makeEmpty():Sphere {
        this.center.set(0, 0, 0);
        this.radius = -1;
        return this;
    }

    public function containsPoint(point:Vector3):Bool {
        return (point.distanceToSquared(this.center) <= (this.radius * this.radius));
    }

    public function distanceToPoint(point:Vector3):Float {
        return (point.distanceTo(this.center) - this.radius);
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
            target.sub(this.center).normalize();
            target.multiplyScalar(this.radius).add(this.center);
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

        _v1.subVectors(point, this.center);

        var lengthSq = _v1.lengthSq();

        if (lengthSq > (this.radius * this.radius)) {
            var length = Math.sqrt(lengthSq);
            var delta = (length - this.radius) * 0.5;
            this.center.addScaledVector(_v1, delta / length);
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
            _v2.subVectors(sphere.center, this.center).setLength(sphere.radius);

            this.expandByPoint(_v1.copy(sphere.center).add(_v2));
            this.expandByPoint(_v1.copy(sphere.center).sub(_v2));
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