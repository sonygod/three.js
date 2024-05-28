package three.math;

import three.math.Vector3;

class Ray {
    public var origin:Vector3;
    public var direction:Vector3;

    public function new(origin:Vector3 = null, direction:Vector3 = null) {
        if (origin == null) origin = new Vector3();
        if (direction == null) direction = new Vector3(0, 0, -1);
        this.origin = origin;
        this.direction = direction;
    }

    public function set(origin:Vector3, direction:Vector3):Ray {
        this.origin.copy(origin);
        this.direction.copy(direction);
        return this;
    }

    public function copy(ray:Ray):Ray {
        this.origin.copy(ray.origin);
        this.direction.copy(ray.direction);
        return this;
    }

    public function at(t:Float, target:Vector3):Vector3 {
        return target.copy(this.origin).addScaledVector(this.direction, t);
    }

    public function lookAt(v:Vector3):Ray {
        this.direction.copy(v).sub(this.origin).normalize();
        return this;
    }

    public function recast(t:Float):Ray {
        this.origin.copy(this.at(t, new Vector3()));
        return this;
    }

    public function closestPointToPoint(point:Vector3, target:Vector3):Vector3 {
        target.subVectors(point, this.origin);
        var directionDistance = target.dot(this.direction);
        if (directionDistance < 0) {
            return target.copy(this.origin);
        }
        return target.copy(this.origin).addScaledVector(this.direction, directionDistance);
    }

    public function distanceToPoint(point:Vector3):Float {
        return Math.sqrt(this.distanceSqToPoint(point));
    }

    public function distanceSqToPoint(point:Vector3):Float {
        var directionDistance = _vector.subVectors(point, this.origin).dot(this.direction);
        if (directionDistance < 0) {
            return this.origin.distanceToSquared(point);
        }
        _vector.copy(this.origin).addScaledVector(this.direction, directionDistance);
        return _vector.distanceToSquared(point);
    }

    public function distanceSqToSegment(v0:Vector3, v1:Vector3, optionalPointOnRay:Vector3 = null, optionalPointOnSegment:Vector3 = null):Float {
        // ... ( implementation identical to JavaScript code )
    }

    public function intersectSphere(sphere:Sphere, target:Vector3):Vector3 {
        // ... ( implementation identical to JavaScript code )
    }

    public function intersectsSphere(sphere:Sphere):Bool {
        return this.distanceSqToPoint(sphere.center) <= (sphere.radius * sphere.radius);
    }

    public function distanceToPlane(plane:Plane):Float {
        // ... ( implementation identical to JavaScript code )
    }

    public function intersectPlane(plane:Plane, target:Vector3):Vector3 {
        // ... ( implementation identical to JavaScript code )
    }

    public function intersectsPlane(plane:Plane):Bool {
        // ... ( implementation identical to JavaScript code )
    }

    public function intersectBox(box:Box3, target:Vector3):Vector3 {
        // ... ( implementation identical to JavaScript code )
    }

    public function intersectsBox(box:Box3):Bool {
        return this.intersectBox(box, _vector) != null;
    }

    public function intersectTriangle(a:Vector3, b:Vector3, c:Vector3, backfaceCulling:Bool, target:Vector3):Vector3 {
        // ... ( implementation identical to JavaScript code )
    }

    public function applyMatrix4(matrix4:Matrix4):Ray {
        this.origin.applyMatrix4(matrix4);
        this.direction.transformDirection(matrix4);
        return this;
    }

    public function equals(ray:Ray):Bool {
        return ray.origin.equals(this.origin) && ray.direction.equals(this.direction);
    }

    public function clone():Ray {
        return new Ray().copy(this);
    }
}

private var _vector:Vector3 = new Vector3();
private var _segCenter:Vector3 = new Vector3();
private var _segDir:Vector3 = new Vector3();
private var _diff:Vector3 = new Vector3();
private var _edge1:Vector3 = new Vector3();
private var _edge2:Vector3 = new Vector3();
private var _normal:Vector3 = new Vector3();