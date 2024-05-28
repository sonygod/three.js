import Vector3 from './Vector3.hx';
import Matrix3 from './Matrix3.hx';

class Plane {
    public isPlane: Bool;
    public normal: Vector3;
    public constant: Float;

    public function new(normal: Vector3 = Vector3.ofData([1, 0, 0]), constant: Float = 0) {
        this.isPlane = true;
        this.normal = normal;
        this.constant = constant;
    }

    public function set(normal: Vector3, constant: Float): Plane {
        this.normal = normal;
        this.constant = constant;
        return this;
    }

    public function setComponents(x: Float, y: Float, z: Float, w: Float): Plane {
        this.normal = Vector3.ofData([x, y, z]);
        this.constant = w;
        return this;
    }

    public function setFromNormalAndCoplanarPoint(normal: Vector3, point: Vector3): Plane {
        this.normal = normal;
        this.constant = -point.dot(normal);
        return this;
    }

    public function setFromCoplanarPoints(a: Vector3, b: Vector3, c: Vector3): Plane {
        var normal = a.sub(b).cross(c.sub(b)).normalize();
        this.setFromNormalAndCoplanarPoint(normal, a);
        return this;
    }

    public function copy(plane: Plane): Plane {
        this.normal = plane.normal;
        this.constant = plane.constant;
        return this;
    }

    public function normalize(): Plane {
        var inverseNormalLength = 1.0 / this.normal.length();
        this.normal.mulScalar(inverseNormalLength);
        this.constant *= inverseNormalLength;
        return this;
    }

    public function negate(): Plane {
        this.constant *= -1;
        this.normal.negate();
        return this;
    }

    public function distanceToPoint(point: Vector3): Float {
        return this.normal.dot(point) + this.constant;
    }

    public function distanceToSphere(sphere: any): Float {
        return this.distanceToPoint(sphere.center) - sphere.radius;
    }

    public function projectPoint(point: Vector3, target: Vector3): Vector3 {
        return target.copy(point).addScaled(this.normal, -this.distanceToPoint(point));
    }

    public function intersectLine(line: any, target: Vector3): Vector3 {
        var direction = line.delta();
        var denominator = this.normal.dot(direction);

        if (denominator == 0) {
            if (this.distanceToPoint(line.start) == 0) {
                return target.copy(line.start);
            }
            return null;
        }

        var t = -(line.start.dot(this.normal) + this.constant) / denominator;

        if (t < 0 || t > 1) {
            return null;
        }

        return target.copy(line.start).addScaled(direction, t);
    }

    public function intersectsLine(line: any): Bool {
        var startSign = this.distanceToPoint(line.start);
        var endSign = this.distanceToPoint(line.end);
        return (startSign < 0 && endSign > 0) || (endSign < 0 && startSign > 0);
    }

    public function intersectsBox(box: any): Bool {
        return box.intersectsPlane(this);
    }

    public function intersectsSphere(sphere: any): Bool {
        return sphere.intersectsPlane(this);
    }

    public function coplanarPoint(target: Vector3): Vector3 {
        return target.copy(this.normal).mulScalar(-this.constant);
    }

    public function applyMatrix4(matrix: any, optionalNormalMatrix: Matrix3 = null): Plane {
        var normalMatrix = optionalNormalMatrix ?? Matrix3.getNormalMatrix(matrix);
        var referencePoint = this.coplanarPoint(Vector3.zero()).applyMatrix4(matrix);
        var normal = this.normal.applyMatrix3(normalMatrix).normalize();
        this.constant = -referencePoint.dot(normal);
        return this;
    }

    public function translate(offset: Vector3): Plane {
        this.constant -= offset.dot(this.normal);
        return this;
    }

    public function equals(plane: Plane): Bool {
        return plane.normal.equals(this.normal) && plane.constant == this.constant;
    }

    public function clone(): Plane {
        return new Plane().copy(this);
    }
}

export { Plane };