package three.js.examples.jsm.math;

import three.js.math.Box3;
import three.js.math.Matrix3;
import three.js.math.Matrix4;
import three.js.math.Ray;
import three.js.math.Vector3;

class OBB {
    public var center:Vector3;
    public var halfSize:Vector3;
    public var rotation:Matrix3;

    public function new(center:Vector3 = new Vector3(), halfSize:Vector3 = new Vector3(), rotation:Matrix3 = new Matrix3()) {
        this.center = center;
        this.halfSize = halfSize;
        this.rotation = rotation;
    }

    public function set(center:Vector3, halfSize:Vector3, rotation:Matrix3):OBB {
        this.center = center;
        this.halfSize = halfSize;
        this.rotation = rotation;
        return this;
    }

    public function copy(obb:OBB):OBB {
        this.center.copy(obb.center);
        this.halfSize.copy(obb.halfSize);
        this.rotation.copy(obb.rotation);
        return this;
    }

    public function clone():OBB {
        return new OBB().copy(this);
    }

    public function getSize(result:Vector3):Vector3 {
        return result.copy(halfSize).multiplyScalar(2);
    }

    public function clampPoint(point:Vector3, result:Vector3):Vector3 {
        var v1:Vector3 = point.subVectors(point, center);
        rotation.extractBasis(xAxis, yAxis, zAxis);

        result.copy(center);

        var x:Float = MathUtils.clamp(v1.dot(xAxis), -halfSize.x, halfSize.x);
        result.add(xAxis.multiplyScalar(x));

        var y:Float = MathUtils.clamp(v1.dot(yAxis), -halfSize.y, halfSize.y);
        result.add(yAxis.multiplyScalar(y));

        var z:Float = MathUtils.clamp(v1.dot(zAxis), -halfSize.z, halfSize.z);
        result.add(zAxis.multiplyScalar(z));

        return result;
    }

    public function containsPoint(point:Vector3):Bool {
        v1.subVectors(point, center);
        rotation.extractBasis(xAxis, yAxis, zAxis);

        return Math.abs(v1.dot(xAxis)) <= halfSize.x &&
               Math.abs(v1.dot(yAxis)) <= halfSize.y &&
               Math.abs(v1.dot(zAxis)) <= halfSize.z;
    }

    public function intersectsBox3(box3:Box3):Bool {
        return intersectsOBB(fromBox3(box3));
    }

    public function intersectsSphere(sphere:Sphere):Bool {
        clampPoint(sphere.center, closestPoint);

        return closestPoint.distanceToSquared(sphere.center) <= (sphere.radius * sphere.radius);
    }

    public function intersectsOBB(obb:OBB, epsilon:Float = Math.EPSILON):Bool {
        a.c = this.center;
        a.e[0] = this.halfSize.x;
        a.e[1] = this.halfSize.y;
        a.e[2] = this.halfSize.z;
        this.rotation.extractBasis(a.u[0], a.u[1], a.u[2]);

        b.c = obb.center;
        b.e[0] = obb.halfSize.x;
        b.e[1] = obb.halfSize.y;
        b.e[2] = obb.halfSize.z;
        obb.rotation.extractBasis(b.u[0], b.u[1], b.u[2]);

        for (i in 0...3) {
            for (j in 0...3) {
                R[i][j] = a.u[i].dot(b.u[j]);
            }
        }

        v1.subVectors(b.c, a.c);

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

        return true;
    }

    public function intersectsPlane(plane:Plane):Bool {
        rotation.extractBasis(xAxis, yAxis, zAxis);

        var r:Float = halfSize.x * Math.abs(plane.normal.dot(xAxis)) +
                      halfSize.y * Math.abs(plane.normal.dot(yAxis)) +
                      halfSize.z * Math.abs(plane.normal.dot(zAxis));

        var d:Float = plane.normal.dot(center) - plane.constant;

        return Math.abs(d) <= r;
    }

    public function intersectRay(ray:Ray, result:Vector3):Vector3 {
        getSize(size);
        aabb.setFromCenterAndSize(v1.set(0, 0, 0), size);

        matrix.setFromMatrix3(rotation);
        matrix.setPosition(center);

        inverse.copy(matrix).invert();
        localRay.copy(ray).applyMatrix4(inverse);

        if (localRay.intersectBox(aabb, result)) {
            return result.applyMatrix4(matrix);
        } else {
            return null;
        }
    }

    public function intersectsRay(ray:Ray):Bool {
        return intersectRay(ray, v1) != null;
    }

    public function fromBox3(box3:Box3):OBB {
        box3.getCenter(center);

        box3.getSize(halfSize).multiplyScalar(0.5);

        rotation.identity();

        return this;
    }

    public function equals(obb:OBB):Bool {
        return obb.center.equals(center) &&
               obb.halfSize.equals(halfSize) &&
               obb.rotation.equals(rotation);
    }

    public function applyMatrix4(matrix:Matrix4):OBB {
        var e:Array<Float> = matrix.elements;

        var sx:Float = v1.set(e[0], e[1], e[2]).length();
        var sy:Float = v1.set(e[4], e[5], e[6]).length();
        var sz:Float = v1.set(e[8], e[9], e[10]).length();

        var det:Float = matrix.determinant();
        if (det < 0) sx = -sx;

        rotationMatrix.setFromMatrix4(matrix);

        var invSX:Float = 1 / sx;
        var invSY:Float = 1 / sy;
        var invSZ:Float = 1 / sz;

        rotationMatrix.elements[0] *= invSX;
        rotationMatrix.elements[1] *= invSX;
        rotationMatrix.elements[2] *= invSX;

        rotationMatrix.elements[3] *= invSY;
        rotationMatrix.elements[4] *= invSY;
        rotationMatrix.elements[5] *= invSY;

        rotationMatrix.elements[6] *= invSZ;
        rotationMatrix.elements[7] *= invSZ;
        rotationMatrix.elements[8] *= invSZ;

        rotation.multiply(rotationMatrix);

        halfSize.x *= sx;
        halfSize.y *= sy;
        halfSize.z *= sz;

        v1.setFromMatrixPosition(matrix);
        center.add(v1);

        return this;
    }
}