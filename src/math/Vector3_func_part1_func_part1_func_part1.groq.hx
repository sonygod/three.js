package three.math;

import haxe.ds.Vector;

class Vector3 {
    public var x:Float;
    public var y:Float;
    public var z:Float;

    public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public function set(x:Float, y:Float, z:Float):Vector3 {
        if (z == null) z = this.z; // sprite.scale.set(x,y)
        this.x = x;
        this.y = y;
        this.z = z;
        return this;
    }

    public function setScalar(scalar:Float):Vector3 {
        this.x = scalar;
        this.y = scalar;
        this.z = scalar;
        return this;
    }

    public function setX(x:Float):Vector3 {
        this.x = x;
        return this;
    }

    public function setY(y:Float):Vector3 {
        this.y = y;
        return this;
    }

    public function setZ(z:Float):Vector3 {
        this.z = z;
        return this;
    }

    public function setComponent(index:Int, value:Float):Vector3 {
        switch (index) {
            case 0: this.x = value;
            case 1: this.y = value;
            case 2: this.z = value;
            default: throw new Error('index is out of range: ' + index);
        }
        return this;
    }

    public function getComponent(index:Int):Float {
        switch (index) {
            case 0: return this.x;
            case 1: return this.y;
            case 2: return this.z;
            default: throw new Error('index is out of range: ' + index);
        }
    }

    public function clone():Vector3 {
        return new Vector3(this.x, this.y, this.z);
    }

    public function copy(v:Vector3):Vector3 {
        this.x = v.x;
        this.y = v.y;
        this.z = v.z;
        return this;
    }

    public function add(v:Vector3):Vector3 {
        this.x += v.x;
        this.y += v.y;
        this.z += v.z;
        return this;
    }

    public function addScalar(s:Float):Vector3 {
        this.x += s;
        this.y += s;
        this.z += s;
        return this;
    }

    public function addVectors(a:Vector3, b:Vector3):Vector3 {
        this.x = a.x + b.x;
        this.y = a.y + b.y;
        this.z = a.z + b.z;
        return this;
    }

    public function addScaledVector(v:Vector3, s:Float):Vector3 {
        this.x += v.x * s;
        this.y += v.y * s;
        this.z += v.z * s;
        return this;
    }

    public function sub(v:Vector3):Vector3 {
        this.x -= v.x;
        this.y -= v.y;
        this.z -= v.z;
        return this;
    }

    public function subScalar(s:Float):Vector3 {
        this.x -= s;
        this.y -= s;
        this.z -= s;
        return this;
    }

    public function subVectors(a:Vector3, b:Vector3):Vector3 {
        this.x = a.x - b.x;
        this.y = a.y - b.y;
        this.z = a.z - b.z;
        return this;
    }

    public function multiply(v:Vector3):Vector3 {
        this.x *= v.x;
        this.y *= v.y;
        this.z *= v.z;
        return this;
    }

    public function multiplyScalar(scalar:Float):Vector3 {
        this.x *= scalar;
        this.y *= scalar;
        this.z *= scalar;
        return this;
    }

    public function multiplyVectors(a:Vector3, b:Vector3):Vector3 {
        this.x = a.x * b.x;
        this.y = a.y * b.y;
        this.z = a.z * b.z;
        return this;
    }

    public function applyEuler(euler:Euler):Vector3 {
        return applyQuaternion(Quaternion.fromEuler(euler));
    }

    public function applyAxisAngle(axis:Vector3, angle:Float):Vector3 {
        return applyQuaternion(Quaternion.fromAxisAngle(axis, angle));
    }

    public function applyMatrix3(m:Matrix3):Vector3 {
        var e:Array<Float> = m.elements;
        var x:Float = this.x, y:Float = this.y, z:Float = this.z;
        this.x = e[0] * x + e[3] * y + e[6] * z;
        this.y = e[1] * x + e[4] * y + e[7] * z;
        this.z = e[2] * x + e[5] * y + e[8] * z;
        return this;
    }

    public function applyNormalMatrix(m:Matrix3):Vector3 {
        return applyMatrix3(m).normalize();
    }

    public function applyMatrix4(m:Matrix4):Vector3 {
        var e:Array<Float> = m.elements;
        var x:Float = this.x, y:Float = this.y, z:Float = this.z;
        var w:Float = 1 / (e[3] * x + e[7] * y + e[11] * z + e[15]);
        this.x = (e[0] * x + e[4] * y + e[8] * z + e[12]) * w;
        this.y = (e[1] * x + e[5] * y + e[9] * z + e[13]) * w;
        this.z = (e[2] * x + e[6] * y + e[10] * z + e[14]) * w;
        return this;
    }

    public function applyQuaternion(q:Quaternion):Vector3 {
        var vx:Float = this.x, vy:Float = this.y, vz:Float = this.z;
        var qx:Float = q.x, qy:Float = q.y, qz:Float = q.z, qw:Float = q.w;
        var tx:Float = 2 * (qy * vz - qz * vy);
        var ty:Float = 2 * (qz * vx - qx * vz);
        var tz:Float = 2 * (qx * vy - qy * vx);
        this.x = vx + qw * tx + qy * tz - qz * ty;
        this.y = vy + qw * ty + qz * tx - qx * tz;
        this.z = vz + qw * tz + qx * ty - qy * tx;
        return this;
    }

    public function project(camera:Camera):Vector3 {
        return applyMatrix4(camera.matrixWorldInverse).applyMatrix4(camera.projectionMatrix);
    }

    public function unproject(camera:Camera):Vector3 {
        return applyMatrix4(camera.projectionMatrixInverse).applyMatrix4(camera.matrixWorld);
    }

    public function transformDirection(m:Matrix4):Vector3 {
        var e:Array<Float> = m.elements;
        var x:Float = this.x, y:Float = this.y, z:Float = this.z;
        this.x = e[0] * x + e[4] * y + e[8] * z;
        this.y = e[1] * x + e[5] * y + e[9] * z;
        this.z = e[2] * x + e[6] * y + e[10] * z;
        return normalize();
    }

    public function divide(v:Vector3):Vector3 {
        this.x /= v.x;
        this.y /= v.y;
        this.z /= v.z;
        return this;
    }

    public function divideScalar(scalar:Float):Vector3 {
        return multiplyScalar(1 / scalar);
    }

    public function min(v:Vector3):Vector3 {
        this.x = Math.min(this.x, v.x);
        this.y = Math.min(this.y, v.y);
        this.z = Math.min(this.z, v.z);
        return this;
    }

    public function max(v:Vector3):Vector3 {
        this.x = Math.max(this.x, v.x);
        this.y = Math.max(this.y, v.y);
        this.z = Math.max(this.z, v.z);
        return this;
    }

    public function clamp(min:Vector3, max:Vector3):Vector3 {
        this.x = Math.max(min.x, Math.min(max.x, this.x));
        this.y = Math.max(min.y, Math.min(max.y, this.y));
        this.z = Math.max(min.z, Math.min(max.z, this.z));
        return this;
    }

    public function clampScalar(minVal:Float, maxVal:Float):Vector3 {
        this.x = Math.max(minVal, Math.min(maxVal, this.x));
        this.y = Math.max(minVal, Math.min(maxVal, this.y));
        this.z = Math.max(minVal, Math.min(maxVal, this.z));
        return this;
    }

    public function clampLength(min:Float, max:Float):Vector3 {
        var length:Float = length();
        return divideScalar(length || 1).multiplyScalar(Math.max(min, Math.min(max, length)));
    }

    public function floor():Vector3 {
        this.x = Math.floor(this.x);
        this.y = Math.floor(this.y);
        this.z = Math.floor(this.z);
        return this;
    }

    public function ceil():Vector3 {
        this.x = Math.ceil(this.x);
        this.y = Math.ceil(this.y);
        this.z = Math.ceil(this.z);
        return this;
    }

    public function round():Vector3 {
        this.x = Math.round(this.x);
        this.y = Math.round(this.y);
        this.z = Math.round(this.z);
        return this;
    }

    public function roundToZero():Vector3 {
        this.x = Math.trunc(this.x);
        this.y = Math.trunc(this.y);
        this.z = Math.trunc(this.z);
        return this;
    }

    public function negate():Vector3 {
        this.x = -this.x;
        this.y = -this.y;
        this.z = -this.z;
        return this;
    }

    public function dot(v:Vector3):Float {
        return this.x * v.x + this.y * v.y + this.z * v.z;
    }

    public function lengthSq():Float {
        return this.x * this.x + this.y * this.y + this.z * this.z;
    }

    public function length():Float {
        return Math.sqrt(lengthSq());
    }

    public function manhattanLength():Float {
        return Math.abs(this.x) + Math.abs(this.y) + Math.abs(this.z);
    }

    public function normalize():Vector3 {
        return divideScalar(length() || 1);
    }

    public function setLength(length:Float):Vector3 {
        return normalize().multiplyScalar(length);
    }

    public function lerp(v:Vector3, alpha:Float):Vector3 {
        this.x += (v.x - this.x) * alpha;
        this.y += (v.y - this.y) * alpha;
        this.z += (v.z - this.z) * alpha;
        return this;
    }

    public function lerpVectors(v1:Vector3, v2:Vector3, alpha:Float):Vector3 {
        this.x = v1.x + (v2.x - v1.x) * alpha;
        this.y = v1.y + (v2.y - v1.y) * alpha;
        this.z = v1.z + (v2.z - v1.z) * alpha;
        return this;
    }

    public function cross(v:Vector3):Vector3 {
        return crossVectors(this, v);
    }

    public function crossVectors(a:Vector3, b:Vector3):Vector3 {
        var ax:Float = a.x, ay:Float = a.y, az:Float = a.z;
        var bx:Float = b.x, by:Float = b.y, bz:Float = b.z;
        this.x = ay * bz - az * by;
        this.y = az * bx - ax * bz;
        this.z = ax * by - ay * bx;
        return this;
    }

    public function projectOnVector(v:Vector3):Vector3 {
        var denominator:Float = v.lengthSq();
        if (denominator == 0) return set(0, 0, 0);
        var scalar:Float = dot(v) / denominator;
        return copy(v).multiplyScalar(scalar);
    }

    public function projectOnPlane(planeNormal:Vector3):Vector3 {
        _vector.copy(this).projectOnVector(planeNormal);
        return sub(_vector);
    }

    public function reflect(normal:Vector3):Vector3 {
        return sub(_vector.copy(normal).multiplyScalar(2 * dot(normal)));
    }

    public function angleTo(v:Vector3):Float {
        var denominator:Float = Math.sqrt(lengthSq() * v.lengthSq());
        if (denominator == 0) return Math.PI / 2;
        var theta:Float = dot(v) / denominator;
        return Math.acos(MathUtils.clamp(theta, -1, 1));
    }

    public function distanceTo(v:Vector3):Float {
        return Math.sqrt(distanceToSquared(v));
    }

    public function distanceToSquared(v:Vector3):Float {
        var dx:Float = this.x - v.x, dy:Float = this.y - v.y, dz:Float = this.z - v.z;
        return dx * dx + dy * dy + dz * dz;
    }

    public function manhattanDistanceTo(v:Vector3):Float {
        return Math.abs(this.x - v.x) + Math.abs(this.y - v.y) + Math.abs(this.z - v.z);
    }

    public function setFromSpherical(s:Spherical):Vector3 {
        return setFromSphericalCoords(s.radius, s.phi, s.theta);
    }

    public function setFromSphericalCoords(radius:Float, phi:Float, theta:Float):Vector3 {
        var sinPhiRadius:Float = Math.sin(phi) * radius;
        this.x = sinPhiRadius * Math.sin(theta);
        this.y = Math.cos(phi) * radius;
        this.z = sinPhiRadius * Math.cos(theta);
        return this;
    }

    public function setFromCylindrical(c:Cylindrical):Vector3 {
        return setFromCylindricalCoords(c.radius, c.theta, c.y);
    }

    public function setFromCylindricalCoords(radius:Float, theta:Float, y:Float):Vector3 {
        this.x = radius * Math.sin(theta);
        this.y = y;
        this.z = radius * Math.cos(theta);
        return this;
    }

    public function setFromMatrixPosition(m:Matrix4):Vector3 {
        var e:Array<Float> = m.elements;
        this.x = e[12];
        this.y = e[13];
        this.z = e[14];
        return this;
    }

    public function setFromMatrixScale(m:Matrix4):Vector3 {
        var sx:Float = setFromMatrixColumn(m, 0).length();
        var sy:Float = setFromMatrixColumn(m, 1).length();
        var sz:Float = setFromMatrixColumn(m, 2).length();
        this.x = sx;
        this.y = sy;
        this.z = sz;
        return this;
    }

    public function setFromMatrixColumn(m:Matrix4, index:Int):Vector3 {
        return fromArray(m.elements, index * 4);
    }

    public function setFromMatrix3Column(m:Matrix3, index:Int):Vector3 {
        return fromArray(m.elements, index * 3);
    }

    public function setFromEuler(e:Euler):Vector3 {
        this.x = e._x;
        this.y = e._y;
        this.z = e._z;
        return this;
    }

    public function setFromColor(c:Color):Vector3 {
        this.x = c.r;
        this.y = c.g;
        this.z = c.b;
        return this;
    }

    public function equals(v:Vector3):Bool {
        return this.x == v.x && this.y == v.y && this.z == v.z;
    }

    public function fromArray(array:Array<Float>, offset:Int = 0):Vector3 {
        this.x = array[offset];
        this.y = array[offset + 1];
        this.z = array[offset + 2];
        return this;
    }

    public function toArray(array:Array<Float> = [], offset:Int = 0):Array<Float> {
        array[offset] = this.x;
        array[offset + 1] = this.y;
        array[offset + 2] = this.z;
        return array;
    }

    public function fromBufferAttribute(attribute:BufferAttribute, index:Int):Vector3 {
        this.x = attribute.getX(index);
        this.y = attribute.getY(index);
        this.z = attribute.getZ(index);
        return this;
    }

    public function random():Vector3 {
        this.x = Math.random();
        this.y = Math.random();
        this.z = Math.random();
        return this;
    }

    public function randomDirection():Vector3 {
        var theta:Float = Math.random() * Math.PI * 2;
        var u:Float = Math.random() * 2 - 1;
        var c:Float = Math.sqrt(1 - u * u);
        this.x = c * Math.sin(theta);
        this.y = u;
        this.z = c * Math.cos(theta);
        return this;
    }

    public function iterator():Iterator<Float> {
        yield this.x;
        yield this.y;
        yield this.z;
    }
}