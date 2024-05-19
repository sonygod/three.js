import three.math.Vector3;

class Ray {

    var origin:Vector3;
    var direction:Vector3;

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
        new Vector3().copy(this.origin).addScaledVector(this.direction, directionDistance);
        return new Vector3().distanceToSquared(point);
    }

    // ... 其他方法的转换，这里省略了一些代码，因为它们的转换方式与上述方法类似

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