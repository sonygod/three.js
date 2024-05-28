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
        var directionDistance:Float = target.dot(this.direction);
        if (directionDistance < 0) {
            return target.copy(this.origin);
        }
        return target.copy(this.origin).addScaledVector(this.direction, directionDistance);
    }

    public function distanceToPoint(point:Vector3):Float {
        return Math.sqrt(this.distanceSqToPoint(point));
    }

    public function distanceSqToPoint(point:Vector3):Float {
        var directionDistance:Float = _vector.subVectors(point, this.origin).dot(this.direction);
        if (directionDistance < 0) {
            return this.origin.distanceToSquared(point);
        }
        _vector.copy(this.origin).addScaledVector(this.direction, directionDistance);
        return _vector.distanceToSquared(point);
    }

    public function distanceSqToSegment(v0:Vector3, v1:Vector3, optionalPointOnRay:Vector3 = null, optionalPointOnSegment:Vector3 = null):Float {
        _segCenter.copy(v0).add(v1).multiplyScalar(0.5);
        _segDir.copy(v1).sub(v0).normalize();
        _diff.copy(this.origin).sub(_segCenter);
        var segExtent:Float = v0.distanceTo(v1) * 0.5;
        var a01:Float = -this.direction.dot(_segDir);
        var b0:Float = _diff.dot(this.direction);
        var b1:Float = - _diff.dot(_segDir);
        var c:Float = _diff.lengthSq();
        var det:Float = Math.abs(1 - a01 * a01);
        var s0:Float, s1:Float, sqrDist:Float, extDet:Float;
        if (det > 0) {
            // The ray and segment are not parallel.
            s0 = a01 * b1 - b0;
            s1 = a01 * b0 - b1;
            extDet = segExtent * det;
            if (s0 >= 0) {
                if (s1 >= -extDet) {
                    if (s1 <= extDet) {
                        // region 0
                        // Minimum at interior points of ray and segment.
                        var invDet:Float = 1 / det;
                        s0 *= invDet;
                        s1 *= invDet;
                        sqrDist = s0 * (s0 + a01 * s1 + 2 * b0) + s1 * (a01 * s0 + s1 + 2 * b1) + c;
                    } else {
                        // region 1
                        s1 = segExtent;
                        s0 = Math.max(0, - (a01 * s1 + b0));
                        sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
                    }
                } else {
                    // region 5
                    s1 = -segExtent;
                    s0 = Math.max(0, - (a01 * s1 + b0));
                    sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
                }
            } else {
                if (s1 <= -extDet) {
                    // region 4
                    s0 = Math.max(0, - (-a01 * segExtent + b0));
                    s1 = (s0 > 0) ? -segExtent : Math.min(Math.max(-segExtent, -b1), segExtent);
                    sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
                } else if (s1 <= extDet) {
                    // region 3
                    s0 = 0;
                    s1 = Math.min(Math.max(-segExtent, -b1), segExtent);
                    sqrDist = s1 * (s1 + 2 * b1) + c;
                } else {
                    // region 2
                    s0 = Math.max(0, - (a01 * segExtent + b0));
                    s1 = (s0 > 0) ? segExtent : Math.min(Math.max(-segExtent, -b1), segExtent);
                    sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
                }
            }
        } else {
            // Ray and segment are parallel.
            s1 = (a01 > 0) ? -segExtent : segExtent;
            s0 = Math.max(0, - (a01 * s1 + b0));
            sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
        }
        if (optionalPointOnRay != null) {
            optionalPointOnRay.copy(this.origin).addScaledVector(this.direction, s0);
        }
        if (optionalPointOnSegment != null) {
            optionalPointOnSegment.copy(_segCenter).addScaledVector(_segDir, s1);
        }
        return sqrDist;
    }

    public function intersectSphere(sphere:Dynamic, target:Vector3):Vector3 {
        _vector.subVectors(sphere.center, this.origin);
        var tca:Float = _vector.dot(this.direction);
        var d2:Float = _vector.dot(_vector) - tca * tca;
        var radius2:Float = sphere.radius * sphere.radius;
        if (d2 > radius2) return null;
        var thc:Float = Math.sqrt(radius2 - d2);
        var t0:Float = tca - thc;
        var t1:Float = tca + thc;
        if (t1 < 0) return null;
        if (t0 < 0) return this.at(t1, target);
        return this.at(t0, target);
    }

    public function intersectsSphere(sphere:Dynamic):Bool {
        return this.distanceSqToPoint(sphere.center) <= (sphere.radius * sphere.radius);
    }

    public function distanceToPlane(plane:Dynamic):Float {
        var denominator:Float = plane.normal.dot(this.direction);
        if (denominator === 0) {
            if (plane.distanceToPoint(this.origin) === 0) {
                return 0;
            }
            return null;
        }
        var t:Float = - (this.origin.dot(plane.normal) + plane.constant) / denominator;
        return t >= 0 ? t : null;
    }

    public function intersectPlane(plane:Dynamic, target:Vector3):Vector3 {
        var t:Float = this.distanceToPlane(plane);
        if (t === null) {
            return null;
        }
        return this.at(t, target);
    }

    public function intersectsPlane(plane:Dynamic):Bool {
        var distToPoint:Float = plane.distanceToPoint(this.origin);
        if (distToPoint === 0) {
            return true;
        }
        var denominator:Float = plane.normal.dot(this.direction);
        if (denominator * distToPoint < 0) {
            return true;
        }
        return false;
    }

    public function intersectBox(box:Dynamic, target:Vector3):Vector3 {
        var tmin:Float, tmax:Float, tymin:Float, tymax:Float, tzmin:Float, tzmax:Float;
        var invdirx:Float = 1 / this.direction.x;
        var invdiry:Float = 1 / this.direction.y;
        var invdirz:Float = 1 / this.direction.z;
        var origin:Vector3 = this.origin;
        if (invdirx >= 0) {
            tmin = (box.min.x - origin.x) * invdirx;
            tmax = (box.max.x - origin.x) * invdirx;
        } else {
            tmin = (box.max.x - origin.x) * invdirx;
            tmax = (box.min.x - origin.x) * invdirx;
        }
        if (invdiry >= 0) {
            tymin = (box.min.y - origin.y) * invdiry;
            tymax = (box.max.y - origin.y) * invdiry;
        } else {
            tymin = (box.max.y - origin.y) * invdiry;
            tymax = (box.min.y - origin.y) * invdiry;
        }
        if ((tmin > tymax) || (tymin > tmax)) return null;
        if (tymin > tmin || isNaN(tmin)) tmin = tymin;
        if (tymax < tmax || isNaN(tmax)) tmax = tymax;
        if (invdirz >= 0) {
            tzmin = (box.min.z - origin.z) * invdirz;
            tzmax = (box.max.z - origin.z) * invdirz;
        } else {
            tzmin = (box.max.z - origin.z) * invdirz;
            tzmax = (box.min.z - origin.z) * invdirz;
        }
        if ((tmin > tzmax) || (tzmin > tmax)) return null;
        if (tzmin > tmin || isNaN(tmin)) tmin = tzmin;
        if (tzmax < tmax || isNaN(tmax)) tmax = tzmax;
        if (tmax < 0) return null;
        return this.at(tmin >= 0 ? tmin : tmax, target);
    }

    public function intersectsBox(box:Dynamic):Bool {
        return this.intersectBox(box, _vector) != null;
    }

    public function intersectTriangle(a:Vector3, b:Vector3, c:Vector3, backfaceCulling:Bool, target:Vector3):Vector3 {
        _edge1.subVectors(b, a);
        _edge2.subVectors(c, a);
        _normal.crossVectors(_edge1, _edge2);
        var DdN:Float = this.direction.dot(_normal);
        var sign:Float;
        if (DdN > 0) {
            if (backfaceCulling) return null;
            sign = 1;
        } else if (DdN < 0) {
            sign = -1;
            DdN = -DdN;
        } else {
            return null;
        }
        _diff.subVectors(this.origin, a);
        var DdQxE2:Float = sign * this.direction.dot(_edge2.cross(_diff));
        if (DdQxE2 < 0) {
            return null;
        }
        var DdE1xQ:Float = sign * this.direction.dot(_edge1.cross(_diff));
        if (DdE1xQ < 0) {
            return null;
        }
        if (DdQxE2 + DdE1xQ > DdN) {
            return null;
        }
        var QdN:Float = - sign * _diff.dot(_normal);
        if (QdN < 0) {
            return null;
        }
        return this.at(QdN / DdN, target);
    }

    public function applyMatrix4(matrix4:Dynamic):Ray {
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

class Vector3 {
    public var x:Float;
    public var y:Float;
    public var z:Float;

    public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public function subVectors(a:Vector3, b:Vector3):Vector3 {
        x = a.x - b.x;
        y = a.y - b.y;
        z = a.z - b.z;
        return this;
    }

    public function dot(v:Vector3):Float {
        return x * v.x + y * v.y + z * v.z;
    }

    public function cross(v:Vector3):Vector3 {
        var ax:Float = x;
        var ay:Float = y;
        var az:Float = z;
        x = ay * v.z - az * v.y;
        y = az * v.x - ax * v.z;
        z = ax * v.y - ay * v.x;
        return this;
    }

    public function normalize():Vector3 {
        var length:Float = Math.sqrt(x * x + y * y + z * z);
        x /= length;
        y /= length;
        z /= length;
        return this;
    }

    public function multiplyScalar(scalar:Float):Vector3 {
        x *= scalar;
        y *= scalar;
        z *= scalar;
        return this;
    }

    public function addScaledVector(v:Vector3, s:Float):Vector3 {
        x += v.x * s;
        y += v.y * s;
        z += v.z * s;
        return this;
    }

    public function distanceTo(v:Vector3):Float {
        var dx:Float = x - v.x;
        var dy:Float = y - v.y;
        var dz:Float = z - v.z;
        return Math.sqrt(dx * dx + dy * dy + dz * dz);
    }

    public function distanceToSquared(v:Vector3):Float {
        var dx:Float = x - v.x;
        var dy:Float = y - v.y;
        var dz:Float = z - v.z;
        return dx * dx + dy * dy + dz * dz;
    }

    public function equals(v:Vector3):Bool {
        return x == v.x && y == v.y && z == v.z;
    }

    public function copy(v:Vector3):Vector3 {
        x = v.x;
        y = v.y;
        z = v.z;
        return this;
    }
}

var _vector:Vector3 = new Vector3();
var _segCenter:Vector3 = new Vector3();
var _segDir:Vector3 = new Vector3();
var _diff:Vector3 = new Vector3();
var _edge1:Vector3 = new Vector3();
var _edge2:Vector3 = new Vector3();
var _normal:Vector3 = new Vector3();