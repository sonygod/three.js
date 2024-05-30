package three.math;

import three.Box3;
import three.Matrix3;
import three.Matrix4;
import three.MathUtils;
import three.Ray;
import three.Vector3;

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
        var halfSize:Vector3 = this.halfSize;
        var v1:Vector3 = point.sub(this.center);
        this.rotation.extractBasis(xAxis, yAxis, zAxis);

        result.copy(this.center);
        var x:Float = MathUtils.clamp(v1.dot(xAxis), -halfSize.x, halfSize.x);
        result.add(xAxis.multiplyScalar(x));

        var y:Float = MathUtils.clamp(v1.dot(yAxis), -halfSize.y, halfSize.y);
        result.add(yAxis.multiplyScalar(y));

        var z:Float = MathUtils.clamp(v1.dot(zAxis), -halfSize.z, halfSize.z);
        result.add(zAxis.multiplyScalar(z));

        return result;
    }

    public function containsPoint(point:Vector3):Bool {
        v1.subVectors(point, this.center);
        this.rotation.extractBasis(xAxis, yAxis, zAxis);

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
        // implementation...
    }

    public function intersectsPlane(plane:Plane):Bool {
        this.rotation.extractBasis(xAxis, yAxis, zAxis);

        var r:Float = halfSize.x * Math.abs(plane.normal.dot(xAxis)) +
                      halfSize.y * Math.abs(plane.normal.dot(yAxis)) +
                      halfSize.z * Math.abs(plane.normal.dot(zAxis));

        var d:Float = plane.normal.dot(this.center) - plane.constant;

        return Math.abs(d) <= r;
    }

    public function intersectRay(ray:Ray, result:Vector3):Vector3 {
        getSize(size);
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
        return intersectRay(ray, v1) != null;
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

        this.rotation.multiply(rotationMatrix);

        this.halfSize.x *= sx;
        this.halfSize.y *= sy;
        this.halfSize.z *= sz;

        v1.setFromMatrixPosition(matrix);
        this.center.add(v1);

        return this;
    }
}

var a:{ c:Vector3, u:Array<Vector3>, e:Array<Float> } = { c: new Vector3(), u: [new Vector3(), new Vector3(), new Vector3()], e: [] };
var b:{ c:Vector3, u:Array<Vector3>, e:Array<Float> } = { c: new Vector3(), u: [new Vector3(), new Vector3(), new Vector3()], e: [] };
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