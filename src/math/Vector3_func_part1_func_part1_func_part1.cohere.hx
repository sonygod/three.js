package;

class Vector3 {
    var x:Float;
    var y:Float;
    var z:Float;
    var isVector3:Bool;

    public function new(x:Float = 0.0, y:Float = 0.0, z:Float = 0.0) {
        this.x = x;
        this.y = y;
        this.z = z;
        isVector3 = true;
    }

    public function set(x:Float, y:Float, ?z:Float):Vector3 {
        if (z == null) z = this.z;
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
            case 0: this.x = value; break;
            case 1: this.y = value; break;
            case 2: this.z = value; break;
            default: throw "Index out of range: $index";
        }
        return this;
    }

    public function getComponent(index:Int):Float {
        switch (index) {
            case 0: return this.x;
            case 1: return this.y;
            case 2: return this.z;
            default: throw "Index out of range: $index";
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

    public function applyEuler(euler:Vector3):Vector3 {
        return this.applyQuaternion(Quaternion.setFromEuler(euler));
    }

    public function applyAxisAngle(axis:Vector3, angle:Float):Vector3 {
        return this.applyQuaternion(Quaternion.setFromAxisAngle(axis, angle));
    }

    public function applyMatrix3(m:Matrix3):Vector3 {
        var x = this.x;
        var y = this.y;
        var z = this.z;
        var e = m.elements;

        this.x = e[0] * x + e[3] * y + e[6] * z;
        this.y = e[1] * x + e[4] * y + e[7] * z;
        this.z = e[2] * x + e[5] * y + e[8] * z;

        return this;
    }

    public function applyNormalMatrix(m:Matrix3):Vector3 {
        return this.applyMatrix3(m).normalize();
    }

    public function applyMatrix4(m:Matrix4):Vector3 {
        var x = this.x;
        var y = this.y;
        var z = this.z;
        var e = m.elements;

        var w = 1 / (e[3] * x + e[7] * y + e[11] * z + e[15]);

        this.x = (e[0] * x + e[4] * y + e[8] * z + e[12]) * w;
        this.y = (e[1] * x + e[5] * y + e[9] * z + e[13]) * w;
        this.z = (e[2] * x + e[6] * y + e[10] * z + e[14]) * w;

        return this;
    }

    public function applyQuaternion(q:Quaternion):Vector3 {
        // quaternion q is assumed to have unit length

        var vx = this.x;
        var vy = this.y;
        var vz = this.z;
        var qx = q.x;
        var qy = q.y;
        var qz = q.z;
        var qw = q.w;

        // t = 2 * cross(q.xyz, v)
        var tx = 2 * (qy * vz - qz * vy);
        var ty = 2 * (qz * vx - qx * vz);
        var tz = 2 * (qx * vy - qy * vx);

        // v + q.w * t + cross(q.xyz, t)
        this.x = vx + qw * tx + qy * tz - qz * ty;
        this.y = vy + qw * ty + qz * tx - qx * tz;
        this.z = vz + qw * tz + qx * ty - qy * tx;

        return this;
    }

    public function project(camera:Camera):Vector3 {
        return this.applyMatrix4(camera.matrixWorldInverse).applyMatrix4(camera.projectionMatrix);
    }

    public function unproject(camera:Camera):Vector3 {
        return this.applyMatrix4(camera.projectionMatrixInverse).applyMatrix4(camera.matrixWorld);
    }

    public function transformDirection(m:Matrix4):Vector3 {
        // input: THREE.Matrix4 affine matrix
        // vector interpreted as a direction

        var x = this.x;
        var y = this.y;
        var z = this.z;
        var e = m.elements;

        this.x = e[0] * x + e[4] * y + e[8] * z;
        this.y = e[1] * x + e[5] * y + e[9] * z;
        this.z = e[2] * x + e[6] * y + e[10] * z;

        return this.normalize();
    }

    public function divide(v:Vector3):Vector3 {
        this.x /= v.x;
        this.y /= v.y;
        this.z /= v.z;
        return this;
    }

    public function divideScalar(scalar:Float):Vector3 {
        return this.multiplyScalar(1 / scalar);
    }

    public function min(v:Vector3):Vector3 {
        this.x = min(this.x, v.x);
        this.y = min(this.y, v.y);
        this.z = min(this.z, v.z);
        return this;
    }

    public function max(v:Vector3):Vector3 {
        this.x = max(this.x, v.x);
        this.y = max(this.y, v.y);
        this.z = max(this.z, v.z);
        return this;
    }

    public function clamp(min:Vector3, max:Vector3):Vector3 {
        // assumes min < max, component-wise

        this.x = max(min.x, min(max.x, this.x));
        this.y = max(min.y, min(max.y, this.y));
        this.z = max(min.z, min(max.z, this.z));

        return this;
    }

    public function clampScalar(minVal:Float, maxVal:Float):Vector3 {
        this.x = max(minVal, min(maxVal, this.x));
        this.y = max(minVal, min(maxVal, this.y));
        this.z = max(minVal, min(maxVal, this.z));
        return this;
    }

    public function clampLength(min:Float, max:Float):Vector3 {
        var length = this.length();
        return this.divideScalar(length || 1).multiplyScalar(max(min, min(max, length)));
    }

    public function floor():Vector3 {
        this.x = Std.int(this.x);
        this.y = Std.int(this.y);
        this.z = Std.int(this.z);
        return this;
    }

    public function ceil():Vector3 {
        this.x = Std.ceil(this.x);
        this.y = Std.ceil(this.y);
        this.z = Std.ceil(this.z);
        return this;
    }

    public function round():Vector3 {
        this.x = Std.round(this.x);
        this.y = Std.round(this.y);
        this.z = Std.round(this.z);
        return this;
    }

    public function roundToZero():Vector3 {
        this.x = Std.int(this.x);
        this.y = Std.int(this.y);
        this.z = Std.int(this.z);
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
        return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
    }

    public function manhattanLength():Float {
        return abs(this.x) + abs(this.y) + abs(this.z);
    }

    public function normalize():Vector3 {
        return this.divideScalar(this.length() or 1);
    }

    public function setLength(length:Float):Vector3 {
        return this.normalize().multiplyScalar(length);
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
        return this.crossVectors(this, v);
    }

    public function crossVectors(a:Vector3, b:Vector3):Vector3 {
        var ax = a.x;
        var ay = a.y;
        var az = a.z;
        var bx = b.x;
        var by = b.y;
        var bz = b.z;

        this.x = ay * bz - az * by;
        this.y = az * bx - ax * bz;
        this.z = ax * by - ay * bx;

        return this;
    }

    public function projectOnVector(v:Vector3):Vector3 {
        var denominator = v.lengthSq();

        if (denominator == 0) return this.set(0, 0, 0);

        var scalar = v.dot(this) / denominator;

        return this.copy(v).multiplyScalar(scalar);
    }

    public function projectOnPlane(planeNormal:Vector3):Vector3 {
        var _vector = Vector3.fromArray([this.x, this.y, this.z]);
        return this.sub(_vector.projectOnVector(planeNormal));
    }

    public function reflect(normal:Vector3):Vector3 {
        // reflect incident vector off plane orthogonal to normal
        // normal is assumed to have unit length

        return this.sub(Vector3.fromArray([normal.x, normal.y, normal.z]).multiplyScalar(2 * this.dot(normal)));
    }

    public function angleTo(v:Vector3):Float {
        var denominator = Math.sqrt(this.lengthSq() * v.lengthSq());

        if (denominator == 0) return Math.PI / 2;

        var theta = this.dot(v) / denominator;

        // clamp, to handle numerical problems

        return Math.acos(Math.clamp(theta, -1, 1));
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

    public function manhattanDistanceTo(v:Vector3):Float {
        return abs(this.x - v.x) + abs(this.y - v.y) + abs(this.z - v.z);
    }

    public function setFromSpherical(s:Vector3):Vector3 {
        return this.setFromSphericalCoords(s.x, s.y, s.z);
    }

    public function setFromSphericalCoords(radius:Float, phi:Float, theta:Float):Vector3 {
        var sinPhiRadius = Math.sin(phi) * radius;

        this.x = sinPhiRadius * Math.sin(theta);
        this.y = Math.cos(phi) * radius;
        this.z = sinPhiRadius * Math.cos(theta);

        return this;
    }

    public function setFromCylindrical(c:Vector3):Vector3 {
        return this.setFromCylindricalCoords(c.x, c.y, c.z);
    }

    public function setFromCylindricalCoords(radius:Float, theta:Float, y:Float):Vector3 {
        this.x = radius * Math.sin(theta);
        this.y = y;
        this.z = radius * Math.cos(theta);

        return this;
    }

    public function setFromMatrixPosition(m:Matrix4):Vector3 {
        var e = m.elements;

        this.x = e[12];
        this.y = e[13];
        this.z = e[14];

        return this;
    }

    public function setFromMatrixScale(m:Matrix4):Vector3 {
        var sx = Vector3.fromArray([m.elements[0], m.elements[1], m.elements[2]]).length();
        var sy = Vector3.fromArray([m.elements[4], m.elements[5], m.elements[6]]).length();
        var sz = Vector3.fromArray([m.elements[8], m.elements[9], m.elements[10]]).length();

        this.x = sx;
        this.y = sy;
        this.z = sz;

        return this;
    }

    public function setFromMatrixColumn(m:Matrix4, index:Int):Vector3 {
        return this.fromArray(m.
    elements, index * 4);
    }

    public function setFromMatrix3Column(m:Matrix3, index:Int):Vector3 {
        return this.fromArray(m.elements, index * 3);
    }

    public function setFromEuler(e:Vector3):Vector3 {
        this.x = e.x;
        this.y = e.y;
        this.z = e.z;
        return this;
    }

    public function setFromColor(c:Vector3):Vector3 {
        this.x = c.x;
        this.y = c.y;
        this.z = c.z;
        return this;
    }

    public function equals(v:Vector3):Bool {
        return (v.x == this.x) && (v.y == this.y) && (v.z == this.z);
    }

    public function fromArray(array:Array<Float>, offset:Int = 0):Vector3 {
        this.x = array[offset];
        this.y = array[offset + 1];
        this.z = array[offset + 2];
        return this;
    }

    public function toArray(?array:Array<Float>, offset:Int = 0):Array<Float> {
        if (array == null) array = [];
        array[offset] = this.x;
        array[offset + 1] = this.y;
        array[offset + 2] = this.z;
        return array;
    }

    public function fromBufferAttribute(attribute:Float32BufferAttribute, index:Int):Vector3 {
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
        // https://mathworld.wolfram.com/SpherePointPicking.html

        var theta = Math.random() * Math.PI * 2;
        var u = Math.random() * 2 - 1;
        var c = Math.sqrt(1 - u * u);

        this.x = c * Math.cos(theta);
        this.y = u;
        this.z = c * Math.sin(theta);

        return this;
    }

    public function __iterator():Vector3Iterator {
        return new Vector3Iterator(this);
    }
}

class Vector3Iterator {
    var v:Vector3;
    var index:Int;

    public function new(v:Vector3) {
        this.v = v;
        this.index = 0;
    }

    public function hasNext():Bool {
        return this.index < 3;
    }

    public function next():Float {
        switch (this.index++) {
            case 0: return v.x;
            case 1: return v.y;
            case 2: return v.z;
        }
    }
}

class Quaternion {
    public static function setFromEuler(e:Vector3):Quaternion {
        // ...
    }

    public static function setFromAxisAngle(axis:Vector3, angle:Float):Quaternion {
        // ...
    }
}

class Matrix3 {
    public var elements:Array<Float>;

    public function new(?elements:Array<Float>) {
        if (elements == null) {
            elements = [
                1, 0, 0,
                0, 1, 0,
                0, 0, 1
            ];
        } else {
            this.elements = elements;
        }
    }
}

class Matrix4 {
    public var elements:Array<Float>;

    public function new(?elements:Array<Float>) {
        if (elements == null) {
            elements = [
                1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1
            ];
        } else {
            this.elements = elements;
        }
    }
}

class Float32BufferAttribute {
    public function getX(index:Int):Float {
        // ...
    }

    public function getY(index:Int):Float {
        // ...
    }

    public function getZ(index:Int):Float {
        // ...
    }
}

class Camera {
    public var matrixWorldInverse:Matrix4;
    public var projectionMatrix:Matrix4;
    public var projectionMatrixInverse:Matrix4;
}

class Math {
    public static function clamp(value:Float, min:Float, max:Float):Float {
        return max(min, min(max, value));
    }
}

class Std {
    public static function int(x:Float):Int {
        return if (x >= 0) Std.floor(x) else Std.ceil(x);
    }

    public static function floor(x:Float):Int {
        return if (x >= 0) Int(x) else Int(x) - 1;
    }

    public static function ceil(x:Float):Int {
        return if (x >= 0) Int(x + 1) else Int(x);
    }

    public static function round(x:Float):Int {
        if (x < 0) {
            var y = x - 0.5;
            return if (y >= -0.5) Int(y) else Int(y) - 1;
        } else {
            var y = x + 0.5;
            return if (y <= 0.5) Int(y) else Int(y) + 1;
        }
    }
}