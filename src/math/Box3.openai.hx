package three.math;

import three.math_Vector3;

class Box3 {
    public var isBox3:Bool = true;
    public var min:Vector3;
    public var max:Vector3;

    public function new(min:Vector3 = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY), max:Vector3 = new Vector3(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY)) {
        this.min = min;
        this.max = max;
    }

    public function set(min:Vector3, max:Vector3):Box3 {
        this.min.copy(min);
        this.max.copy(max);
        return this;
    }

    public function setFromArray(array:Array<Float>):Box3 {
        makeEmpty();
        for (i in 0...Std.int(array.length / 3)) {
            expandByPoint(Vector3.fromArray(array, i * 3));
        }
        return this;
    }

    public function setFromBufferAttribute(attribute:BufferAttribute):Box3 {
        makeEmpty();
        for (i in 0...attribute.count) {
            expandByPoint(Vector3.fromBufferAttribute(attribute, i));
        }
        return this;
    }

    public function setFromPoints(points:Array<Vector3>):Box3 {
        makeEmpty();
        for (point in points) {
            expandByPoint(point);
        }
        return this;
    }

    public function setFromCenterAndSize(center:Vector3, size:Vector3):Box3 {
        var halfSize:Vector3 = size.clone().multiplyScalar(0.5);
        this.min.copy(center).sub(halfSize);
        this.max.copy(center).add(halfSize);
        return this;
    }

    public function setFromObject(object:Object3D, precise:Bool = false):Box3 {
        makeEmpty();
        return expandByObject(object, precise);
    }

    public function clone():Box3 {
        return new Box3().copy(this);
    }

    public function copy(box:Box3):Box3 {
        this.min.copy(box.min);
        this.max.copy(box.max);
        return this;
    }

    public function makeEmpty():Box3 {
        this.min.x = this.min.y = this.min.z = Math.POSITIVE_INFINITY;
        this.max.x = this.max.y = this.max.z = Math.NEGATIVE_INFINITY;
        return this;
    }

    public function isEmpty():Bool {
        return (this.max.x < this.min.x) || (this.max.y < this.min.y) || (this.max.z < this.min.z);
    }

    public function getCenter(target:Vector3):Vector3 {
        return isEmpty() ? target.set(0, 0, 0) : target.addVectors(this.min, this.max).multiplyScalar(0.5);
    }

    public function getSize(target:Vector3):Vector3 {
        return isEmpty() ? target.set(0, 0, 0) : target.subVectors(this.max, this.min);
    }

    public function expandByPoint(point:Vector3):Box3 {
        this.min.min(point);
        this.max.max(point);
        return this;
    }

    public function expandByVector(vector:Vector3):Box3 {
        this.min.sub(vector);
        this.max.add(vector);
        return this;
    }

    public function expandByScalar(scalar:Float):Box3 {
        this.min.addScalar(-scalar);
        this.max.addScalar(scalar);
        return this;
    }

    public function expandByObject(object:Object3D, precise:Bool = false):Box3 {
        object.updateWorldMatrix(false, false);

        var geometry:Geometry = object.geometry;
        if (geometry != null) {
            var positionAttribute:BufferAttribute = geometry.getAttribute('position');

            if (precise && positionAttribute != null && !object.isInstancedMesh) {
                for (i in 0...positionAttribute.count) {
                    var vector:Vector3 = object.getVertexPosition(i);
                    vector.applyMatrix4(object.matrixWorld);
                    expandByPoint(vector);
                }
            } else {
                if (object.boundingBox != null) {
                    var box:Box3 = object.boundingBox;
                } else {
                    geometry.computeBoundingBox();
                    box = geometry.boundingBox;
                }
                box.applyMatrix4(object.matrixWorld);
                union(box);
            }
        }

        var children:Array<Object3D> = object.children;
        for (child in children) {
            expandByObject(child, precise);
        }
        return this;
    }

    public function containsPoint(point:Vector3):Bool {
        return point.x < this.min.x || point.x > this.max.x || point.y < this.min.y || point.y > this.max.y || point.z < this.min.z || point.z > this.max.z ? false : true;
    }

    public function containsBox(box:Box3):Bool {
        return this.min.x <= box.min.x && box.max.x <= this.max.x && this.min.y <= box.min.y && box.max.y <= this.max.y && this.min.z <= box.min.z && box.max.z <= this.max.z;
    }

    public function getParameter(point:Vector3, target:Vector3):Vector3 {
        if (isEmpty()) {
            return target.set(0, 0, 0);
        }
        return target.set(
            (point.x - this.min.x) / (this.max.x - this.min.x),
            (point.y - this.min.y) / (this.max.y - this.min.y),
            (point.z - this.min.z) / (this.max.z - this.min.z)
        );
    }

    public function intersectsBox(box:Box3):Bool {
        return box.max.x < this.min.x || box.min.x > this.max.x || box.max.y < this.min.y || box.min.y > this.max.y || box.max.z < this.min.z || box.min.z > this.max.z ? false : true;
    }

    public function intersectsSphere(sphere:Sphere):Bool {
        var clampVector:Vector3 = clampPoint(sphere.center, new Vector3());
        return clampVector.distanceToSquared(sphere.center) <= (sphere.radius * sphere.radius);
    }

    public function intersectsPlane(plane:Plane):Bool {
        var min:Float, max:Float;
        if (plane.normal.x > 0) {
            min = plane.normal.x * this.min.x;
            max = plane.normal.x * this.max.x;
        } else {
            min = plane.normal.x * this.max.x;
            max = plane.normal.x * this.min.x;
        }
        if (plane.normal.y > 0) {
            min += plane.normal.y * this.min.y;
            max += plane.normal.y * this.max.y;
        } else {
            min += plane.normal.y * this.max.y;
            max += plane.normal.y * this.min.y;
        }
        if (plane.normal.z > 0) {
            min += plane.normal.z * this.min.z;
            max += plane.normal.z * this.max.z;
        } else {
            min += plane.normal.z * this.max.z;
            max += plane.normal.z * this.min.z;
        }
        return (min <= -plane.constant && max >= -plane.constant);
    }

    public function intersectsTriangle(triangle:Triangle):Bool {
        if (isEmpty()) {
            return false;
        }
        var center:Vector3 = new Vector3();
        getCenter(center);
        var extents:Vector3 = getSize(new Vector3());
        var v0:Vector3 = triangle.a.clone().sub(center);
        var v1:Vector3 = triangle.b.clone().sub(center);
        var v2:Vector3 = triangle.c.clone().sub(center);
        var f0:Vector3 = v1.clone().sub(v0);
        var f1:Vector3 = v2.clone().sub(v1);
        var f2:Vector3 = v0.clone().sub(v2);
        var axes:Array<Float> = [
            0, -f0.z, f0.y, 0, -f1.z, f1.y, 0, -f2.z, f2.y,
            f0.z, 0, -f0.x, f1.z, 0, -f1.x, f2.z, 0, -f2.x,
            -f0.y, f0.x, 0, -f1.y, f1.x, 0, -f2.y, f2.x, 0
        ];
        if (!satForAxes(axes, v0, v1, v2, extents)) {
            return false;
        }
        axes = [1, 0, 0, 0, 1, 0, 0, 0, 1];
        if (!satForAxes(axes, v0, v1, v2, extents)) {
            return false;
        }
        var triangleNormal:Vector3 = f0.cross(f1);
        axes = [triangleNormal.x, triangleNormal.y, triangleNormal.z];
        return satForAxes(axes, v0, v1, v2, extents);
    }

    public function clampPoint(point:Vector3, target:Vector3):Vector3 {
        return target.copy(point).clamp(this.min, this.max);
    }

    public function distanceToPoint(point:Vector3):Float {
        return clampPoint(point, new Vector3()).distanceTo(point);
    }

    public function getBoundingSphere(target:Sphere):Sphere {
        if (isEmpty()) {
            target.makeEmpty();
        } else {
            getCenter(target.center);
            target.radius = getSize(new Vector3()).length() * 0.5;
        }
        return target;
    }

    public function intersect(box:Box3):Box3 {
        this.min.max(box.min);
        this.max.min(box.max);
        if (isEmpty()) makeEmpty();
        return this;
    }

    public function union(box:Box3):Box3 {
        this.min.min(box.min);
        this.max.max(box.max);
        return this;
    }

    public function applyMatrix4(matrix:Matrix4):Box3 {
        if (isEmpty()) return this;
        var points:Array<Vector3> = [
            new Vector3(), new Vector3(), new Vector3(), new Vector3(), new Vector3(), new Vector3(), new Vector3(), new Vector3()
        ];
        points[0].set(this.min.x, this.min.y, this.min.z).applyMatrix4(matrix);
        points[1].set(this.min.x, this.min.y, this.max.z).applyMatrix4(matrix);
        points[2].set(this.min.x, this.max.y, this.min.z).applyMatrix4(matrix);
        points[3].set(this.min.x, this.max.y, this.max.z).applyMatrix4(matrix);
        points[4].set(this.max.x, this.min.y, this.min.z).applyMatrix4(matrix);
        points[5].set(this.max.x, this.min.y, this.max.z).applyMatrix4(matrix);
        points[6].set(this.max.x, this.max.y, this.min.z).applyMatrix4(matrix);
        points[7].set(this.max.x, this.max.y, this.max.z).applyMatrix4(matrix);
        setFromPoints(points);
        return this;
    }

    public function translate(offset:Vector3):Box3 {
        this.min.add(offset);
        this.max.add(offset);
        return this;
    }

    public function equals(box:Box3):Bool {
        return box.min.equals(this.min) && box.max.equals(this.max);
    }
}

function satForAxes(axes:Array<Float>, v0:Vector3, v1:Vector3, v2:Vector3, extents:Vector3):Bool {
    for (i in 0...axes.length - 3) {
        var testAxis:Vector3 = new Vector3();
        testAxis.fromArray(axes, i);
        var r:Float = extents.x * Math.abs(testAxis.x) + extents.y * Math.abs(testAxis.y) + extents.z * Math.abs(testAxis.z);
        var p0:Float = v0.dot(testAxis);
        var p1:Float = v1.dot(testAxis);
        var p2:Float = v2.dot(testAxis);
        if (Math.max(-Math.max(p0, p1, p2), Math.min(p0, p1, p2)) > r) return false;
    }
    return true;
}