import three.math.Box3;
import three.math.MathUtils;
import three.math.Matrix4;
import three.math.Matrix3;
import three.math.Ray;
import three.math.Vector3;

class OBB {
    var center:Vector3;
    var halfSize:Vector3;
    var rotation:Matrix3;

    var a:Dynamic = {
        c: null, // center
        u: [ new Vector3(), new Vector3(), new Vector3() ], // basis vectors
        e: [] // half width
    };

    var b:Dynamic = {
        c: null, // center
        u: [ new Vector3(), new Vector3(), new Vector3() ], // basis vectors
        e: [] // half width
    };

    var R:Array<Array<Float>> = [[], [], []];
    var AbsR:Array<Array<Float>> = [[], [], []];
    var t:Array<Float> = [];

    var xAxis:Vector3 = new Vector3();
    var yAxis:Vector3 = new Vector3();
    var zAxis:Vector3 = new Vector3();
    var v1:Vector3 = new Vector3();
    var size:Vector3 = new Vector3();
    var closestPoint:Vector3 = new Vector3();
    var rotationMatrix:Matrix3 = new Matrix3();
    var aabb:Box3 = new Box3();
    var matrix:Matrix4 = new Matrix4();
    var inverse:Matrix4 = new Matrix4();
    var localRay:Ray = new Ray();

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
        return result.copy(this.halfSize).multiplyScalar(2);
    }

    public function clampPoint(point:Vector3, result:Vector3):Vector3 {
        var halfSize = this.halfSize;
        v1.subVectors(point, this.center);
        this.rotation.extractBasis(xAxis, yAxis, zAxis);
        result.copy(this.center);
        var x = MathUtils.clamp(v1.dot(xAxis), -halfSize.x, halfSize.x);
        result.add(xAxis.multiplyScalar(x));
        var y = MathUtils.clamp(v1.dot(yAxis), -halfSize.y, halfSize.y);
        result.add(yAxis.multiplyScalar(y));
        var z = MathUtils.clamp(v1.dot(zAxis), -halfSize.z, halfSize.z);
        result.add(zAxis.multiplyScalar(z));
        return result;
    }

    public function containsPoint(point:Vector3):Bool {
        v1.subVectors(point, this.center);
        this.rotation.extractBasis(xAxis, yAxis, zAxis);
        return Math.abs(v1.dot(xAxis)) <= this.halfSize.x &&
               Math.abs(v1.dot(yAxis)) <= this.halfSize.y &&
               Math.abs(v1.dot(zAxis)) <= this.halfSize.z;
    }

    public function intersectsBox3(box3:Box3):Bool {
        return this.intersectsOBB(new OBB().fromBox3(box3));
    }

    public function intersectsSphere(sphere):Bool {
        this.clampPoint(sphere.center, closestPoint);
        return closestPoint.distanceToSquared(sphere.center) <= (sphere.radius * sphere.radius);
    }

    public function intersectsOBB(obb:OBB, epsilon:Float = Number.EPSILON):Bool {
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

        for (var i:Int = 0; i < 3; i++) {
            for (var j:Int = 0; j < 3; j++) {
                R[i][j] = a.u[i].dot(b.u[j]);
            }
        }

        v1.subVectors(b.c, a.c);

        t[0] = v1.dot(a.u[0]);
        t[1] = v1.dot(a.u[1]);
        t[2] = v1.dot(a.u[2]);

        for (var i:Int = 0; i < 3; i++) {
            for (var j:Int = 0; j < 3; j++) {
                AbsR[i][j] = Math.abs(R[i][j]) + epsilon;
            }
        }

        var ra:Float;
        var rb:Float;

        for (var i:Int = 0; i < 3; i++) {
            ra = a.e[i];
            rb = b.e[0] * AbsR[i][0] + b.e[1] * AbsR[i][1] + b.e[2] * AbsR[i][2];
            if (Math.abs(t[i]) > ra + rb) return false;
        }

        for (var i:Int = 0; i < 3; i++) {
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

    public function intersectsPlane(plane):Bool {
        this.rotation.extractBasis(xAxis, yAxis, zAxis);
        var r = this.halfSize.x * Math.abs(plane.normal.dot(xAxis)) +
                 this.halfSize.y * Math.abs(plane.normal.dot(yAxis)) +
                 this.halfSize.z * Math.abs(plane.normal.dot(zAxis));
        var d = plane.normal.dot(this.center) - plane.constant;
        return Math.abs(d) <= r;
    }

    public function intersectRay(ray:Ray, result:Vector3):Vector3 {
        this.getSize(size);
        aabb.setFromCenterAndSize(v1.set(0, 0, 0), size);
        matrix.setFromMatrix3(this.rotation);
        matrix.setPosition(this.center);
        inverse.copy(matrix).invert();
        localRay.copy(ray).applyMatrix4(inverse);
        if (localRay.intersectBox(aabb, result)) {
            return result.applyMatrix4(matrix);
        } else {
            return null;
        }
    }

    public function intersectsRay(ray:Ray):Bool {
        return this.intersectRay(ray, v1) !== null;
    }

    public function fromBox3(box3:Box3):OBB {
        box3.getCenter(this.center);
        box3.getSize(this.halfSize).multiplyScalar(0.5);
        this.rotation.identity();
        return this;
    }

    public function equals(obb:OBB):Bool {
        return obb.center.equals(this.center) &&
               obb.halfSize.equals(this.halfSize) &&
               obb.rotation.equals(this.rotation);
    }

    public function applyMatrix4(matrix:Matrix4):OBB {
        var e = matrix.elements;
        var sx = v1.set(e[0], e[1], e[2]).length();
        var sy = v1.set(e[4], e[5], e[6]).length();
        var sz = v1.set(e[8], e[9], e[10]).length();
        var det = matrix.determinant();
        if (det < 0) sx = -sx;
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
        v1.setFromMatrixPosition(matrix);
        this.center.add(v1);
        return this;
    }
}

var obb = new OBB();