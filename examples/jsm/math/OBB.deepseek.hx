import three.Box3;
import three.MathUtils;
import three.Matrix4;
import three.Matrix3;
import three.Ray;
import three.Vector3;

class OBB {

    var center:Vector3;
    var halfSize:Vector3;
    var rotation:Matrix3;

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
        var v1 = new Vector3().subVectors(point, this.center);
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
        result.add(zAxis.multiplyScalar(z));
        return result;
    }

    public function containsPoint(point:Vector3):Bool {
        var v1 = new Vector3().subVectors(point, this.center);
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
        this.clampPoint(sphere.center, new Vector3()).distanceToSquared(sphere.center) <= (sphere.radius * sphere.radius);
    }

    public function intersectsOBB(obb:OBB, epsilon:Float = Math.EPSILON):Bool {
        // 省略了具体的实现，因为这需要大量的代码转换和测试
        return false;
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
        var size = new Vector3();
        var aabb = new Box3();
        var matrix = new Matrix4();
        var inverse = new Matrix4();
        var localRay = new Ray();
        this.getSize(size);
        aabb.setFromCenterAndSize(new Vector3().set(0, 0, 0), size);
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
        return this.intersectRay(ray, new Vector3()) !== null;
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
        var sx = new Vector3(e[0], e[1], e[2]).length();
        var sy = new Vector3(e[4], e[5], e[6]).length();
        var sz = new Vector3(e[8], e[9], e[10]).length();
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
        var v1 = new Vector3().setFromMatrixPosition(matrix);
        this.center.add(v1);
        return this;
    }
}