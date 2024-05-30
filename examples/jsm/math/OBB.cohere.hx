import MathUtils from js.three.MathUtils;
import Matrix4 from js.three.Matrix4;
import Matrix3 from js.three.Matrix3;
import Ray from js.three.Ray;
import Vector3 from js.three.Vector3;

class OBB {
    public var center:Vector3;
    public var halfSize:Vector3;
    public var rotation:Matrix3;

    public function new(?center:Vector3, ?halfSize:Vector3, ?rotation:Matrix3) {
        this.center = center ? center : new Vector3();
        this.halfSize = halfSize ? halfSize : new Vector3();
        this.rotation = rotation ? rotation : new Matrix3();
    }

    public function set(center:Vector3, halfSize:Vector3, rotation:Matrix3):Void {
        this.center = center;
        this.halfSize = halfSize;
        this.rotation = rotation;
    }

    public function copy(obb:OBB):This {
        this.center.copy(obb.center);
        this.halfSize.copy(obb.halfSize);
        this.rotation.copy(obb.rotation);
        return this;
    }

    public function clone():OBB {
        return new OBB().copy(this);
    }

    public function getSize(result:Vector3):Vector3 {
        return result.copy(this.halfSize).multiplyScalar(2);
    }

    public function clampPoint(point:Vector3, result:Vector3):Vector3 {
        var halfSize = this.halfSize;
        var v1 = point.clone().sub(this.center);
        var xAxis = new Vector3();
        var yAxis = new Vector3();
        var zAxis = new Vector3();
        this.rotation.extractBasis(xAxis, yAxis, zAxis);

        result.copy(this.center);
        var x = MathUtils.clamp(v1.dot(xAxis), -halfSize.x, halfSize.x);
        result.add(xAxis.multiplyScalar(x));

        var y = MathUtils.clamp(v1.dot(yAxis), -halfSize.y, halfSize.y);
        result.add(yAxis.multiplyScalar(y));

        var z = MathUtils.clamp(v1.dot(zAxis), -halfSize.z, halfSize.z);
        return result.add(zAxis.multiplyScalar(z));
    }

    public function containsPoint(point:Vector3):Bool {
        var v1 = point.clone().sub(this.center);
        var xAxis = new Vector3();
        var yAxis = new Vector3();
        var zAxis = new Vector3();
        this.rotation.extractBasis(xAxis, yAxis, zAxis);

        return Math.abs(v1.dot(xAxis)) <= this.halfSize.x &&
               Math.abs(v1.dot(yAxis)) <= this.halfSize.y &&
               Math.abs(v1.dot(zAxis)) <= this.halfSize.z;
    }

    public function intersectsBox3(box3:Box3):Bool {
        return this.intersectsOBB(OBB.fromBox3(box3));
    }

    public function intersectsSphere(sphere:Sphere):Bool {
        var closestPoint = this.clampPoint(sphere.center, new Vector3());
        return closestPoint.distanceToSquared(sphere.center) <= (sphere.radius * sphere.radius);
    }

    public function intersectsOBB(obb:OBB, epsilon:Float = MathUtils.EPSILON):Bool {
        var a = { c: this.center, e: [this.halfSize.x, this.halfSize.y, this.halfSize.z], u: [] as Array<Vector3> };
        var b = { c: obb.center, e: [obb.halfSize.x, obb.halfSize.y, obb.halfSize.z], u: [] as Array<Vector3> };

        var R = [[], [], []];
        var AbsR = [[], [], []];
        var t = [];

        var xAxis = new Vector3();
        var yAxis = new Vector3();
        var zAxis = new Vector3();

        a.u[0] = xAxis.copy(this.rotation.elements[0] as Vector3);
        a.u[1] = yAxis.copy(this.rotation.elements[3] as Vector3);
        a.u[2] = zAxis.copy(this.rotation.elements[6] as Vector3);

        b.u[0] = xAxis.copy(obb.rotation.elements[0] as Vector3);
        b.u[1] = yAxis.copy(obb.rotation.elements[3] as Vector3);
        b.u[2] = zAxis.copy(obb.rotation.elements[6] as Vector3);

        for (i in 0...3) {
            for (j in 0...3) {
                R[i][j] = a.u[i].dot(b.u[j]);
            }
        }

        var v1 = b.c.clone().sub(a.c);

        t[0] = v1.dot(a.u[0]);
        t[1] = v1.dot(a.u[1]);
        t[2] = v1.dot(a.u[2]);

        for (i in 0...3) {
            for (j in 0...3) {
                AbsR[i][j] = Math.abs(R[i][j]) + epsilon;
            }
        }

        var ra:Float, rb:Float;

        for (i in 0...3) {
            ra = a.e[i];
            rb = b.e[0] * AbsR[i][0] + b.e[1] * AbsR[i][1] + b.e[2] * AbsR[i][2];
            if (Math.abs(t[i]) > ra + rb) return false;
        }

        for (i in 0...3) {
            ra = a.e[0] * AbsR[0][i] + a.e[1] * AbsR[1][i] + a.e[2] * AbsR[2][i];
            rb = b.e[i];
            if (Math.abs(t[0] * R[0][i] + t[1] * R[1][i] + t[2] * R[2][i]) > ra + rb) return false;
        }

        ra = a.e[1] * AbsR[2][0] + a.e[2] * AbsR[1][0];
        rb = b.e[1] * AbsR[0][2] + b.e[2] * AbsR[0][1];
        if (Math.abs(t[2] * R[1][0] - t[1] * R[2][0]) > ra + rb) return false;

        ra = a.e[1] * AbsR[2][1] + a.e[2] * AbsR[1][1];
        rb = b.e[0] * AbsR[0][2] + b.e[2] * AbsR[0][0];
        if (Math.abs(t[2] * R[1][1] - t[1] * R[2][1]) > ra + rb) return false;

        ra = a.e[1] * AbsR[2][2] + a.e[2] * AbsR[1][2];
        rb = b.e[0] * AbsR[0][1] + b.e[1] * AbsR[0][0];
        if (Math.abs(t[2] * R[1][2] - t[1] * R[2][2]) > ra + rb) return false;

        ra = a.e[0] * AbsR[2][0] + a.e[2] * AbsR[0][0];
        rb = b.e[1] * AbsR[1][2] + b.e[2] * AbsR[1][1];
        if (Math.abs(t[0] * R[2][0] - t[2] * R[0][0]) > ra + rb) return false;

        ra = a.e[0] * AbsR[2][1] + a.e[2] * AbsR[0][1];
        rb = b.e[0] * AbsR[1][2] + b.e[2] * AbsR[1][0];
        if (Math.abs(t[0] * R[2][1] - t[2] * R[0][1]) > ra + rb) return false;

        ra = a.e[0] * AbsR[2][2] + a.e[2] * AbsR[0][2];
        rb = b.e[0] * AbsR[1][1] + b.e[1] * AbsR[1][0];
        if (Math.abs(t[0] * R[2][2] - t[2] * R[0][2]) > ra + rb) return false;

        ra = a.e[0] * AbsR[1][0] + a.e[1] * AbsR[0][0];
        rb = b.e[1] * AbsR[2][2] + b.e[2] * AbsR[2][1];
        if (Math.abs(t[1] * R[0][0] - t[0] * R[1][0]) > ra + rb) return false;

        ra = a.e[0] * AbsR[1][1] + a.e[1] * AbsR[0][1];
        rb = b.e[0] * AbsR[2][2] + b.e[2] * AbsR[2][0];
        if (Math.abs(t[1] * R[0][1] - t[0] * R[1][1]) > ra + rb) return false;

        ra = a.e[0] * AbsR[1][2] + a.e[1] * AbsR[0][2];
        rb = b.e[0] * AbsR[2][1] + b.e[1] * AbsR[2][0];
        if (Math.abs(t[1] * R[0][2] - t[0] * R[1][2]) > ra + rb) return false;

        return true;
    }

    public function intersectsPlane(plane:Plane):Bool {
        var xAxis = new Vector3();
        var yAxis = new Vector3();
        var zAxis = new Vector3();
        this.rotation.extractBasis(xAxis, yAxis, zAxis);

        var r = this.halfSize.x * Math.abs(plane.normal.dot(xAxis)) +
               this.halfSize.y * Math.abs(plane.normal.dot(yAxis)) +
               this.halfSize.z * Math.abs(plane.normal.dot(zAxis));

        var d = plane.normal.dot(this.center) - plane.constant;
        return Math.abs(d) <= r;
    }

    public function intersectRay(ray:Ray, result:Vector3):Vector3 {
        var size = this.getSize(new Vector3());
        var aabb = new Box3();
        aabb.setFromCenterAndSize(new Vector3(), size);

        var matrix = new Matrix4();
        matrix.setFromMatrix3(this.rotation);
        matrix.setPosition(this.center);

        var inverse = matrix.clone().invert();
        var localRay = ray.clone().applyMatrix4(inverse);

        if (localRay.intersectBox(aabb, result)) {
            return result.applyMatrix4(matrix);
        } else {
            return null;
        }
    }

    public function intersectsRay(ray:Ray):Bool {
        return this.intersectRay(ray, new Vector3()) != null;
    }

    public static function fromBox3(box3:Box3):OBB {
        var obb = new OBB();
        obb.center = box3.getCenter(new Vector3());
        obb.halfSize = box3.getSize(new Vector3()).multiplyScalar(0.5);
        obb.rotation.identity();
        return obb;
    }

    public function equals(obb:OBB):Bool {
        return obb.center.equals(this.center) &&
               obb.halfSize.equals(this.halfSize) &&
               obb.rotation.equals(this.rotation);
    }

    public function applyMatrix4(matrix:Matrix4):This {
        var e = matrix.elements;

        var sx = (e[0] * e[0] + e[1] * e[1] + e[2] * e[2]).sqrt();
        var sy = (e[4] * e[4] + e[5] * e[5] + e[6] * e[6]).sqrt();
        var sz = (e[8] * e[8] + e[9] * e[9] + e[10] * e[10]).sqrt();

        var det = matrix.determinant();
        if (det < 0) sx = -sx;

        var rotationMatrix = new Matrix3();
        rotationMatrix.setFromMatrix4(matrix);

        var invSX = 1 / sx;
        var invSY = 1 / sy;
        var invSZ = 1 / sz;

        rotationMatrix.elements[0] *= invSX;
        rotationMatrix.elements[1] *= invSX;
        rotationMatrix.elements[2] *= invSX;

        rotationMatrix.elements[3] *= invSY;
        rotationMatrix.elements[4] *= invSY;
        rotationMatrix.elements[5] *= invSY;

        rotationMatrix.elements[6] *= invSZ;
        rotationMatrix.elements[7] *= invSZ;
        rotationMatrix.elements[8] *= invSZ;

        this.rotation.multiply(rotationMatrix);

        this.halfSize.x *= sx;
        this.halfSize.y *= sy;
        this.halfSize.z *= sz;

        var v1 = new Vector3();
        v1.setFromMatrixPosition(matrix);
        this.center.add(v1);

        return this;
    }
}

var obb = new OBB();

class Box3 {
    public function getCenter(target:Vector3):Vector3 {
        return target.addVectors(this.min, this.max).multiplyScalar(0.5);
    }

    public function getSize(target:Vector3):Vector3 {
        return target.subVectors(this.max, this.min);
    }

    public function setFromCenterAndSize(center:Vector3, size:Vector3):Void {
        this.makeEmpty();
        this.expandByPoint(center);
        this.expandByVector(size);
    }

    public function expandByPoint(point:Vector3):Void {
        this.expandByVector(point.sub(this.min));
        this.expandByVector(this.max.sub(point));
    }

    public function expandByVector(vector:Vector3):Void {
        if (vector.x < 0) {
            this.min.x += vector.x;
        } else {
            this.max.x += vector.x;
        }

        if (vector.y < 0) {
            this.min.y += vector.y;
        } else {
            this.max.y += vector.y;
        }

        if (vector.z < 0) {
            this.min.z += vector.z;
        } else {
            this.max.z += vector.z;
        }
    }
}

class Sphere {
    public var center:Vector3;
    public var radius:Float;

    public function new(?center:Vector3, ?radius:Float) {
        this.center = center ? center : new Vector3();
        this.radius = radius ? radius : 0.0;
    }
}

class Plane {
    public var normal:Vector3;
    public var constant:Float;

    public function new(?normal:Vector3, ?constant:Float) {
        this.normal = normal ? normal : new Vector3();
        this.constant = constant ? constant : 0.0;
    }
}

class Ray {
    public var origin:Vector3;
    public var direction:Vector3;

    public function new(?origin:Vector3, ?direction:Vector3) {
        this.origin = origin ? origin : new Vector3();
        this.direction = direction ? direction : new Vector3();
    }

    public function applyMatrix4(matrix:Matrix4):This {
        this.origin.applyMatrix4(matrix);
        this.direction.transformDirection(matrix);
        return this;
    }

    public function intersectBox(box:Box3, target:Vector3):Bool {
        var tmin, tmax, tymin, tymax, tzmin, tzmax;

        var invdirx = 1.0 / this.direction.x;
        var invdiry = 1.0 / this.direction.y;
        var invdirz = 1.0 / this.direction.z;

        var origin = this.origin;

        if (invdirx >= 0.0) {
            tmin = (box.min.x - origin.x) * invdirx;
            tmax = (box.max.x - origin.x) * invdirx;
        } else {
            tmin = (box.max.x - origin.x) * invdirx;
            tmax = (box.min.x - origin.x) * inv