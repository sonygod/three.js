import Vector3 from "./Vector3";

class Ray {
  public origin:Vector3;
  public direction:Vector3;

  public function new(origin:Vector3 = new Vector3(), direction:Vector3 = new Vector3(0, 0, -1)) {
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
    var directionDistance = new Vector3().subVectors(point, this.origin).dot(this.direction);
    if (directionDistance < 0) {
      return this.origin.distanceToSquared(point);
    }
    var vector = new Vector3().copy(this.origin).addScaledVector(this.direction, directionDistance);
    return vector.distanceToSquared(point);
  }

  public function distanceSqToSegment(v0:Vector3, v1:Vector3, optionalPointOnRay:Vector3 = null, optionalPointOnSegment:Vector3 = null):Float {
    var segCenter = new Vector3().copy(v0).add(v1).multiplyScalar(0.5);
    var segDir = new Vector3().copy(v1).sub(v0).normalize();
    var diff = new Vector3().copy(this.origin).sub(segCenter);

    var segExtent = v0.distanceTo(v1) * 0.5;
    var a01 = - this.direction.dot(segDir);
    var b0 = diff.dot(this.direction);
    var b1 = - diff.dot(segDir);
    var c = diff.lengthSq();
    var det = Math.abs(1 - a01 * a01);
    var s0:Float, s1:Float, sqrDist:Float, extDet:Float;

    if (det > 0) {
      s0 = a01 * b1 - b0;
      s1 = a01 * b0 - b1;
      extDet = segExtent * det;

      if (s0 >= 0) {
        if (s1 >= - extDet) {
          if (s1 <= extDet) {
            var invDet = 1 / det;
            s0 *= invDet;
            s1 *= invDet;
            sqrDist = s0 * (s0 + a01 * s1 + 2 * b0) + s1 * (a01 * s0 + s1 + 2 * b1) + c;
          } else {
            s1 = segExtent;
            s0 = Math.max(0, - (a01 * s1 + b0));
            sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
          }
        } else {
          s1 = - segExtent;
          s0 = Math.max(0, - (a01 * s1 + b0));
          sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
        }
      } else {
        if (s1 <= - extDet) {
          s0 = Math.max(0, - (- a01 * segExtent + b0));
          s1 = (s0 > 0) ? - segExtent : Math.min(Math.max(- segExtent, - b1), segExtent);
          sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
        } else if (s1 <= extDet) {
          s0 = 0;
          s1 = Math.min(Math.max(- segExtent, - b1), segExtent);
          sqrDist = s1 * (s1 + 2 * b1) + c;
        } else {
          s0 = Math.max(0, - (a01 * segExtent + b0));
          s1 = (s0 > 0) ? segExtent : Math.min(Math.max(- segExtent, - b1), segExtent);
          sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
        }
      }
    } else {
      s1 = (a01 > 0) ? - segExtent : segExtent;
      s0 = Math.max(0, - (a01 * s1 + b0));
      sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
    }

    if (optionalPointOnRay != null) {
      optionalPointOnRay.copy(this.origin).addScaledVector(this.direction, s0);
    }

    if (optionalPointOnSegment != null) {
      optionalPointOnSegment.copy(segCenter).addScaledVector(segDir, s1);
    }

    return sqrDist;
  }

  public function intersectSphere(sphere:Dynamic, target:Vector3):Vector3 {
    var vector = new Vector3().subVectors(sphere.center, this.origin);
    var tca = vector.dot(this.direction);
    var d2 = vector.dot(vector) - tca * tca;
    var radius2 = sphere.radius * sphere.radius;

    if (d2 > radius2) return null;

    var thc = Math.sqrt(radius2 - d2);
    var t0 = tca - thc;
    var t1 = tca + thc;

    if (t1 < 0) return null;

    if (t0 < 0) return this.at(t1, target);

    return this.at(t0, target);
  }

  public function intersectsSphere(sphere:Dynamic):Bool {
    return this.distanceSqToPoint(sphere.center) <= (sphere.radius * sphere.radius);
  }

  public function distanceToPlane(plane:Dynamic):Float {
    var denominator = plane.normal.dot(this.direction);

    if (denominator == 0) {
      if (plane.distanceToPoint(this.origin) == 0) {
        return 0;
      }
      return null;
    }

    var t = - (this.origin.dot(plane.normal) + plane.constant) / denominator;
    return t >= 0 ? t : null;
  }

  public function intersectPlane(plane:Dynamic, target:Vector3):Vector3 {
    var t = this.distanceToPlane(plane);
    if (t == null) {
      return null;
    }
    return this.at(t, target);
  }

  public function intersectsPlane(plane:Dynamic):Bool {
    var distToPoint = plane.distanceToPoint(this.origin);
    if (distToPoint == 0) {
      return true;
    }

    var denominator = plane.normal.dot(this.direction);
    if (denominator * distToPoint < 0) {
      return true;
    }

    return false;
  }

  public function intersectBox(box:Dynamic, target:Vector3):Vector3 {
    var tmin:Float, tmax:Float, tymin:Float, tymax:Float, tzmin:Float, tzmax:Float;
    var invdirx = 1 / this.direction.x;
    var invdiry = 1 / this.direction.y;
    var invdirz = 1 / this.direction.z;
    var origin = this.origin;

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

    if (tymin > tmin || Math.isNaN(tmin)) tmin = tymin;
    if (tymax < tmax || Math.isNaN(tmax)) tmax = tymax;

    if (invdirz >= 0) {
      tzmin = (box.min.z - origin.z) * invdirz;
      tzmax = (box.max.z - origin.z) * invdirz;
    } else {
      tzmin = (box.max.z - origin.z) * invdirz;
      tzmax = (box.min.z - origin.z) * invdirz;
    }

    if ((tmin > tzmax) || (tzmin > tmax)) return null;

    if (tzmin > tmin || tmin !== tmin) tmin = tzmin;
    if (tzmax < tmax || tmax !== tmax) tmax = tzmax;

    if (tmax < 0) return null;

    return this.at(tmin >= 0 ? tmin : tmax, target);
  }

  public function intersectsBox(box:Dynamic):Bool {
    return this.intersectBox(box, new Vector3()) != null;
  }

  public function intersectTriangle(a:Vector3, b:Vector3, c:Vector3, backfaceCulling:Bool = true, target:Vector3 = null):Vector3 {
    var edge1 = new Vector3().subVectors(b, a);
    var edge2 = new Vector3().subVectors(c, a);
    var normal = new Vector3().crossVectors(edge1, edge2);
    var DdN = this.direction.dot(normal);
    var sign:Int;

    if (DdN > 0) {
      if (backfaceCulling) return null;
      sign = 1;
    } else if (DdN < 0) {
      sign = -1;
      DdN = - DdN;
    } else {
      return null;
    }

    var diff = new Vector3().subVectors(this.origin, a);
    var DdQxE2 = sign * this.direction.dot(edge2.crossVectors(diff, edge2));

    if (DdQxE2 < 0) {
      return null;
    }

    var DdE1xQ = sign * this.direction.dot(edge1.cross(diff));
    if (DdE1xQ < 0) {
      return null;
    }

    if (DdQxE2 + DdE1xQ > DdN) {
      return null;
    }

    var QdN = - sign * diff.dot(normal);
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

export default Ray;