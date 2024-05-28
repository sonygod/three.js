package three.math;

import three.Vector3;

class Box3 {
    public var isBox3:Bool = true;

    public var min:Vector3;
    public var max:Vector3;

    public function new(min:Vector3 = null, max:Vector3 = null) {
        min = min != null ? min : new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
        max = max != null ? max : new Vector3(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);
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
        for (i in 0...array.length step 3) {
            expandByPoint(Vector3.fromArray(array, i));
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
        // ...
        return this;
    }

    public function containsPoint(point:Vector3):Bool {
        return (point.x < this.min.x) || (point.x > this.max.x) || (point.y < this.min.y) || (point.y > this.max.y) || (point.z < this.min.z) || (point.z > this.max.z) ? false : true;
    }

    public function containsBox(box:Box3):Bool {
        return this.min.x <= box.min.x && box.max.x <= this.max.x &&
               this.min.y <= box.min.y && box.max.y <= this.max.y &&
               this.min.z <= box.min.z && box.max.z <= this.max.z;
    }

    public function getParameter(point:Vector3, target:Vector3):Vector3 {
        return target.set(
            (point.x - this.min.x) / (this.max.x - this.min.x),
            (point.y - this.min.y) / (this.max.y - this.min.y),
            (point.z - this.min.z) / (this.max.z - this.min.z)
        );
    }

    public function intersectsBox(box:Box3):Bool {
        return box.max.x < this.min.x || box.min.x > this.max.x ||
               box.max.y < this.min.y || box.min.y > this.max.y ||
               box.max.z < this.min.z || box.min.z > this.max.z ? false : true;
    }

    public function intersectsSphere(sphere:Sphere):Bool {
        // ...
        return false;
    }

    public function intersectsPlane(plane:Plane):Bool {
        // ...
        return false;
    }

    public function intersectsTriangle(triangle:Triangle):Bool {
        // ...
        return false;
    }

    public function clampPoint(point:Vector3, target:Vector3):Vector3 {
        return target.copy(point).clamp(this.min, this.max);
    }

    public function distanceToPoint(point:Vector3):Float {
        return clampPoint(point, _vector).distanceTo(point);
    }

    public function getBoundingSphere(target:Sphere):Sphere {
        if (isEmpty()) {
            target.makeEmpty();
        } else {
            getCenter(target.center);
            target.radius = (getSize(_vector).length() * 0.5);
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
        // ...
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

class Vector3 {
    public var x:Float;
    public var y:Float;
    public var z:Float;

    public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public function addScalar(s:Float):Vector3 {
        x += s;
        y += s;
        z += s;
        return this;
    }

    public function set(x:Float, y:Float, z:Float):Vector3 {
        this.x = x;
        this.y = y;
        this.z = z;
        return this;
    }

    // ...
}

class Matrix4 {
    // ...
}

class BufferAttribute {
    // ...
}

class Object3D {
    // ...
}

class Triangle {
    // ...
}

class Plane {
    // ...
}

class Sphere {
    // ...
}

class BufferGeometry {
    // ...
}