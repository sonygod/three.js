import Math.*;
import js.Browser;

class Vector3 {
    var x:Float;
    var y:Float;
    var z:Float;

    public function new(?x:Float, ?y:Float, ?z:Float) {
        this.x = x ?? 0.0;
        this.y = y ?? 0.0;
        this.z = z ?? 0.0;
    }

    public function set(x:Float, y:Float, z:Float):Void {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public function add(a:Vector3):Void {
        this.x += a.x;
        this.y += a.y;
        this.z += a.z;
    }

    public function addVectors(a:Vector3, b:Vector3):Void {
        this.x = a.x + b.x;
        this.y = a.y + b.y;
        this.z = a.z + b.z;
    }

    public function addScaledVector(a:Vector3, s:Float):Void {
        this.x += a.x * s;
        this.y += a.y * s;
        this.z += a.z * s;
    }

    public function sub(a:Vector3):Void {
        this.x -= a.x;
        this.y -= a.y;
        this.z -= a.z;
    }

    public function subVectors(a:Vector3, b:Vector3):Void {
        this.x = a.x - b.x;
        this.y = a.y - b.y;
        this.z = a.z - b.z;
    }

    public function multiply(a:Vector3):Void {
        this.x *= a.x;
        this.y *= a.y;
        this.z *= a.z;
    }

    public function multiplyVectors(a:Vector3, b:Vector3):Void {
        this.x = a.x * b.x;
        this.y = a.y * b.y;
        this.z = a.z * b.z;
    }

    public function applyEuler(e:Euler):Void {
        var quaternion = new Quaternion();
        e.toQuaternion(quaternion);
        this.applyQuaternion(quaternion);
    }

    public function applyAxisAngle(axis:Vector3, angle:Float):Void {
        var quaternion = new Quaternion();
        quaternion.setFromAxisAngle(axis, angle);
        this.applyQuaternion(quaternion);
    }

    public function applyMatrix3(m:Matrix3):Void {
        var x = this.x;
        var y = this.y;
        var z = this.z;
        this.x = m.elements[0] * x + m.elements[3] * y + m.elements[6] * z;
        this.y = m.elements[1] * x + m.elements[4] * y + m.elements[7] * z;
        this.z = m.elements[2] * x + m.elements[5] * y + m.elements[8] * z;
    }

    public function applyMatrix4(m:Matrix4):Void {
        var x = this.x;
        var y = this.y;
        var z = this.z;
        var w = m.elements[3] * x + m.elements[7] * y + m.elements[11] * z + m.elements[15];
        w = w || 1.0;
        this.x = (m.elements[0] * x + m.elements[4] * y + m.elements[8] * z + m.elements[12]) / w;
        this.y = (m.elements[1] * x + m.elements[5] * y + m.elements[9] * z + m.elements[13]) / w;
        this.z = (m.elements[2] * x + m.elements[6] * y + m.elements[10] * z + m.elements[14]) / w;
    }

    public function applyQuaternion(q:Quaternion):Void {
        var x = this.x;
        var y = this.y;
        var z = this.z;
        var qx = q.x;
        var qy = q.y;
        var qz = q.z;
        var qw = q.w;
        // calculate quat * vector
        var ix = qw * x + qy * z - qz * y;
        var iy = qw * y + qz * x - qx * z;
        var iz = qw * z + qx * y - qy * x;
        var iw = -qx * x - qy * y - qz * z;
        // calculate result * inverse quat
        this.x = ix * qw + iw * -qx + iy * -qz - iz * -qy;
        this.y = iy * qw + iw * -qy + iz * -qx - ix * -qz;
        this.z = iz * qw + iw * -qz + ix * -qy - iy * -qx;
    }

    public function transformDirection(m:Matrix4):Void {
        var x = this.x;
        var y = this.y;
        var z = this.z;
        this.x = m.elements[0] * x + m.elements[4] * y + m.elements[8] * z;
        this.y = m.elements[1] * x + m.elements[5] * y + m.elements[9] * z;
        this.z = m.elements[2] * x + m.elements[6] * y + m.elements[10] * z;
    }

    public function negate():Void {
        this.x = -this.x;
        this.y = -this.y;
        this.z = -this.z;
    }

    public function dot(v:Vector3):Float {
        return this.x * v.x + this.y * v.y + this.z * v.z;
    }

    public function cross(a:Vector3):Void {
        var x = this.x;
        var y = this.y;
        var z = this.z;
        this.x = y * a.z - z * a.y;
        this.y = z * a.x - x * a.z;
        this.z = x * a.y - y * a.x;
    }

    public function crossVectors(a:Vector3, b:Vector3):Void {
        var ax = a.x;
        var ay = a.y;
        var az = a.z;
        var bx = b.x;
        var by = b.y;
        var bz = b.z;
        this.x = ay * bz - az * by;
        this.y = az * bx - ax * bz;
        this.z = ax * by - ay * bx;
    }

    public function projectOnVector(v:Vector3):Vector3 {
        var scalar = this.dot(v) / v.lengthSq();
        return this.copy().multiplyScalar(scalar);
    }

    public function projectOnPlane(planeNormal:Vector3):Vector3 {
        var v1 = new Vector3();
        var v2 = new Vector3();
        v1.copy(this);
        v2.copy(planeNormal);
        v2.multiplyScalar(this.dot(planeNormal));
        v1.sub(v2);
        return v1;
    }

    public function reflect(normal:Vector3):Vector3 {
        var v1 = new Vector3();
        var v2 = new Vector3();
        v1.copy(this);
        v2.copy(normal);
        v2.multiplyScalar(2.0 * this.dot(normal));
        v1.sub(v2);
        return v1;
    }

    public function angleTo(v:Vector3):Float {
        var denominator = Math.sqrt(this.lengthSq() * v.lengthSq());
        if (denominator == 0.0) return 0.0;
        var theta = this.dot(v) / denominator;
        theta = Math.clamp(theta, -1.0, 1.0);
        return Math.acos(theta);
    }

    public function setFromSpherical(s:Spherical):Void {
        var sinPhiRadius = Math.sin(s.phi) * s.radius;
        this.x = sinPhiRadius * Math.sin(s.theta);
        this.y = Math.cos(s.phi) * s.radius;
        this.z = sinPhiRadius * Math.cos(s.theta);
    }

    public function setFromCylindrical(c:Cylindrical):Void {
        this.x = c.radius * Math.sin(c.theta);
        this.y = c.y;
        this.z = c.radius * Math.cos(c.theta);
    }

    public function setFromMatrixPosition(m:Matrix4):Void {
        this.x = m.elements[12];
        this.y = m.elements[13];
        this.z = m.elements[14];
    }

    public function setFromMatrixScale(m:Matrix4):Void {
        var sx = this.setFromMatrixColumn(m, 0).length;
        var sy = this.setFromMatrixColumn(m, 1).length;
        var sz = this.setFromMatrixColumn(m, 2).length;
        this.x = sx;
        this.y = sy;
        this.z = sz;
    }

    public function setFromMatrixColumn(m:Matrix4, index:Int):Vector3 {
        var x = m.elements[index * 4];
        var y = m.elements[index * 4 + 1];
        var z = m.elements[index * 4 + 2];
        this.x = x;
        this.y = y;
        this.z = z;
        return this;
    }

    public function equals(v:Vector3, e:Float = 0.0000001):Bool {
        return (Math.abs(this.x - v.x) <= e) && (Math.abs(this.y - v.y) <= e) && (Math.abs(this.z - v.z) <= e);
    }

    public function fromArray(array:Array<Float>, offset:Int = 0):Void {
        this.x = array[offset];
        this.y = array[offset + 1];
        this.z = array[offset + 2];
    }

    public function toArray(?array:Array<Float>, offset:Int = 0):Array<Float> {
        if (array == null) array = [];
        array[offset] = this.x;
        array[offset + 1] = this.y;
        array[offset + 2] = this.z;
        return array;
    }

    public function fromBufferAttribute(attribute:BufferAttribute, index:Int, offset:Int = 0):Void {
        this.x = attribute.getX(index);
        this.y = attribute.getY(index);
        this.z = attribute.getZ(index);
    }

    public function randomDirection():Vector3 {
        var phi = Math.random() * 2.0 * Math.PI;
        var theta = Math.acos(Math.random() * 2.0 - 1.0);
        this.x = Math.sin(theta) * Math.cos(phi);
        this.y = Math.sin(theta) * Math.sin(phi);
        this.z = Math.cos(theta);
        return this;
    }

    public function setX(x:Float):Void {
        this.x = x;
    }

    public function setY(y:Float):Void {
        this.y = y;
    }

    public function setZ(z:Float):Void {
        this.z = z;
    }

    public function setComponent(index:Int, value:Float):Void {
        switch (index) {
            case 0:
                this.x = value;
                break;
            case 1:
                this.y = value;
                break;
            case 2:
                this.z = value;
                break;
            default:
                throw "index is out of range";
        }
    }

    public function getComponent(index:Int):Float {
        switch (index) {
            case 0:
                return this.x;
            case 1:
                return this.y;
            case 2:
                return this.z;
            default:
                throw "index is out of range";
        }
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
        this.x = Math.clamp(this.x, min.x, max.x);
        this.y = Math.clamp(this.y, min.y, max.y);
        this.z = Math.clamp(this.z, min.z, max.z);
        return this;
    }

    public function distanceTo(v:Vector3):Float {
        return Math.sqrt(this.distanceToSquared(v));
    }

    public function distanceToSquared(v:Vector3):Float {
        var dx = this.x - v.x;
        var dy = this.y - v.y;
        var dz = this.z - v.z;
        return dx * dx + dy * dy + dz * dz;
    }

    public function setScalar(scalar:Float):Vector3 {
        this.x = scalar;
        this.y = scalar;
        this.z = scalar;
        return this;
    }

    public function addScalar(s:Float):Vector3 {
        this.x += s;
        this.y += s;
        this.z += s;
        return this;
    }

    public function subScalar(s:Float):Vector3 {
        this.x -= s;
        this.y -= s;
        this.z -= s;
        return this;
    }

    public function multiplyScalar(s:Float):Vector3 {
        this.x *= s;
        this.y *= s;
        this.z *= s;
        return this;
    }

    public function divideScalar(s:Float):Vector3 {
        return this.multiplyScalar(1.0 / s);
    }

    public function length():Float {
        return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
    }

    public function lengthSq():Float {
        return this.x * this.x + this.y * this.y + this.z * this.z;
    }

    public function manhattanLength():Float {
        return Math.abs(this.x) + Math.abs(this.y) + Math.abs(this.z);
    }

    public function normalize():Vector3 {
        return this.divideScalar(this.length());
    }

    public function setLength(l:Float):Vector3 {
        return this.normalize().multiplyScalar(l);
    }

    public function lerp(v:Vector3, alpha:Float):Vector3 {
        this.x += (v.x - this.x) * alpha;
        this.y += (v.y - this.y) * alpha;
        this.z += (v.z - this.z) * alpha;
        return this;
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

    public function toArray(?array:Array<Float>, offset:Int = 0):Array<Float> {
        if (array == null) array = [];
        array[offset] = this.x;
        array[offset + 1] = this.y;
        array[offset + 2] = this.z;
        return array;
    }

    public function toJSON():String {
        return "[" + this.toArray().join(",") + "]";
    }

    public function toString():String {
        return "Vector3(" + this.toArray().join(",") + ")";
    }
}

class Vector4 {
    var x:Float;
    var y:Float;
    var z:Float;
    var w:Float;

    public function new(?x:Float, ?y:Float, ?z:Float, ?w:Float) {
        this.x = x ?? 0.0;
        this.y = y ?? 0.0;
        this.z = z ?? 0.0;
        this.w = w ?? 1.0;
    }

    public function set(x:Float, y:Float, z:Float, w:Float):Void {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    public function applyMatrix4(m:Matrix4):Vector4 {
        var x = this.x;
        var y = this.y;
        var z = this.z;
        var w = this.