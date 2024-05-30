import MathUtils;
import Quaternion;

class Vector3 {
    public var x: Float;
    public var y: Float;
    public var z: Float;

    public static var isVector3: Bool = true;

    public function new(x: Float = 0, y: Float = 0, z: Float = 0) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public function set(x: Float, y: Float, z: Float): Vector3 {
        if (z == null) z = this.z; // sprite.scale.set(x,y)
        this.x = x;
        this.y = y;
        this.z = z;
        return this;
    }

    public function setScalar(scalar: Float): Vector3 {
        this.x = scalar;
        this.y = scalar;
        this.z = scalar;
        return this;
    }

    public function setX(x: Float): Vector3 {
        this.x = x;
        return this;
    }

    public function setY(y: Float): Vector3 {
        this.y = y;
        return this;
    }

    public function setZ(z: Float): Vector3 {
        this.z = z;
        return this;
    }

    public function setComponent(index: Int, value: Float): Vector3 {
        switch (index) {
            case 0: this.x = value; break;
            case 1: this.y = value; break;
            case 2: this.z = value; break;
            default: throw 'index is out of range: ' + index;
        }
        return this;
    }

    public function getComponent(index: Int): Float {
        switch (index) {
            case 0: return this.x;
            case 1: return this.y;
            case 2: return this.z;
            default: throw 'index is out of range: ' + index;
        }
    }

    public function clone(): Vector3 {
        return new Vector3(this.x, this.y, this.z);
    }

    public function copy(v: Vector3): Vector3 {
        this.x = v.x;
        this.y = v.y;
        this.z = v.z;
        return this;
    }

    public function add(v: Vector3): Vector3 {
        this.x += v.x;
        this.y += v.y;
        this.z += v.z;
        return this;
    }

    public function addScalar(s: Float): Vector3 {
        this.x += s;
        this.y += s;
        this.z += s;
        return this;
    }

    public function addVectors(a: Vector3, b: Vector3): Vector3 {
        this.x = a.x + b.x;
        this.y = a.y + b.y;
        this.z = a.z + b.z;
        return this;
    }

    public function addScaledVector(v: Vector3, s: Float): Vector3 {
        this.x += v.x * s;
        this.y += v.y * s;
        this.z += v.z * s;
        return this;
    }

    public function sub(v: Vector3): Vector3 {
        this.x -= v.x;
        this.y -= v.y;
        this.z -= v.z;
        return this;
    }

    public function subScalar(s: Float): Vector3 {
        this.x -= s;
        this.y -= s;
        this.z -= s;
        return this;
    }

    public function subVectors(a: Vector3, b: Vector3): Vector3 {
        this.x = a.x - b.x;
        this.y = a.y - b.y;
        this.z = a.z - b.z;
        return this;
    }

    public function multiply(v: Vector3): Vector3 {
        this.x *= v.x;
        this.y *= v.y;
        this.z *= v.z;
        return this;
    }

    public function multiplyScalar(scalar: Float): Vector3 {
        this.x *= scalar;
        this.y *= scalar;
        this.z *= scalar;
        return this;
    }

    public function multiplyVectors(a: Vector3, b: Vector3): Vector3 {
        this.x = a.x * b.x;
        this.y = a.y * b.y;
        this.z = a.z * b.z;
        return this;
    }

    public function applyEuler(euler: Euler): Vector3 {
        return this.applyQuaternion(_quaternion.setFromEuler(euler));
    }

    public function applyAxisAngle(axis: Vector3, angle: Float): Vector3 {
        return this.applyQuaternion(_quaternion.setFromAxisAngle(axis, angle));
    }

    public function applyMatrix3(m: Matrix3): Vector3 {
        var x = this.x;
        var y = this.y;
        var z = this.z;
        var e = m.elements;
        this.x = e[0] * x + e[3] * y + e[6] * z;
        this.y = e[1] * x + e[4] * y + e[7] * z;
        this.z = e[2] * x + e[5] * y + e[8] * z;
        return this;
    }

    public function applyNormalMatrix(m: Matrix3): Vector3 {
        return this.applyMatrix3(m).normalize();
    }

    public function applyMatrix4(m: Matrix4): Vector3 {
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

    public function applyQuaternion(q: Quaternion): Vector3 {
        // quaternion q is assumed to have unit length
        var vx = this.x;
        var vy = this.y;
        var vz = this.z;
        var qx = q.x;
        var qy = q.y;
        var qz = q.z;
        var qw = q.w;
        // t = 2 * cross( q.xyz, v );
        var tx = 2 * (qy * vz - qz * vy);
        var ty = 2 * (qz * vx - qx * vz);
        var tz = 2 * (qx * vy - qy * vx);
        // v + q.w * t + cross( q.xyz, t );
        this.x = vx + qw * tx + qy * tz - qz * ty;
        this.y = vy + qw * ty + qz * tx - qx * tz;
        this.z = vz + qw * tz + qx * ty - qy * tx;
        return this;
    }

    public function project(camera: Camera): Vector3 {
        return this.applyMatrix4(camera.matrixWorldInverse).applyMatrix4(camera.projectionMatrix);
    }

    public function unproject(camera: Camera): Vector3 {
        return this.applyMatrix4(camera.projectionMatrixInverse).applyMatrix4(camera.matrixWorld);
    }

    public function transformDirection(m: Matrix4): Vector3 {
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

    public function divide(v: Vector3): Vector3 {
        this.x /= v.x;
        this.y /= v.y;
        this.z /= v.z;
        return this;
    }

    public function divideScalar(scalar: Float): Vector3 {
        return this.multiplyScalar(1 / scalar);
    }

    public function min(v: Vector3): Vector3 {
        this.x = Math.min(this.x, v.x);
        this.y = Math.min(this.y, v.y);
        this.z = Math.min(this.z, v.z);
        return this;
    }

    public function max(v: Vector3): Vector3 {
        this.x = Math.max(this.x, v.x);
        this.y = Math.max(this.y, v.y);
        this.z = Math.max(this.z, v.z);
        return this;
    }

    public function clamp(min: Vector3, max: Vector3): Vector3 {
        // assumes min < max, componentwise
        this.x = Math.max(min.x, Math.min(max.x, this.x));
        this.y = Math.max(min.y, Math.min(max.y, this.y));
        this.z = Math.max(min.z, Math.min(max.z, this.z));
        return this;
    }

    public function clampScalar(minVal: Float, maxVal: Float): Vector3 {
        return this.clamp(new Vector3(minVal, minVal, minVal), new Vector3(maxVal, maxVal, maxVal));
    }

    public function clampLength(min: Float, max: Float): Vector3 {
        var length = this.length();
        return this.divideScalar(length || 1).multiplyScalar(Math.max(min, Math.min(max, length)));
    }

    public function floor(): Vector3 {
        this.x = Math.floor(this.x);
        this.y = Math.floor(this.y);
        this.z = Math.floor(this.z);
        return this;
    }

    public function ceil(): Vector3 {
        this.x = Math.ceil(this.x);
        this.y = Math.ceil(this.y);
        this.z = Math.ceil(this.z);
        return this;
    }

    public function round(): Vector3 {
        this.x = Math.round(this.x);
        this.y = Math.round(this.y);
        this.z = Math.round(this.z);
        return this;
    }

    public function roundToZero(): Vector3 {
        this.x = (this.x < 0) ? Math.ceil(this.x) : Math.floor(this.x);
        this.y = (this.y < 0) ? Math.ceil(this.y) : Math.floor(this.y);
        this.z = (this.z < 0) ? Math.ceil(this.z) : Math.floor(this.z);
        return this;
    }

    public function negate(): Vector3 {
        this.x = -this.x;
        this.y = -this.y;
        this.z = -this.z;
        return this;
    }

    public function dot(v: Vector3): Float {
        return this.x * v.x + this.y * v.y + this.z * v.z;
    }

    public function lengthSq(): Float {
        return this.x * this.x + this.y * this.y + this.z * this.z;
    }

    public function length(): Float {
        return Math.sqrt(this.lengthSq());
    }

    public function manhattanLength(): Float {
        return Math.abs(this.x) + Math.abs(this.y) + Math.abs(this.z);
    }

    public function normalize(): Vector3 {
        return this.divideScalar(this.length() || 1);
    }

    public function setLength(length: Float): Vector3 {
        return this.normalize().multiplyScalar(length);
    }

    public function lerp(v: Vector3, alpha: Float): Vector3 {
        this.x += (v.x - this.x) * alpha;
        this.y += (v.y - this.y) * alpha;
        this.z += (v.z - this.z) * alpha;
        return this;
    }

    public function lerpVectors(v1: Vector3, v2: Vector3, alpha: Float): Vector3 {
        this.x = v1.x + (v2.x - v1.x) * alpha;
        this.y = v1.y + (v2.y - v1.y) * alpha;
        this.z = v1.z + (v2.z - v1.z) * alpha;
        return this;
    }

    public function cross(v: Vector3): Vector3 {
        return this.crossVectors(this, v);
    }

    public function crossVectors(a: Vector3, b: Vector3): Vector3 {
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

    public function projectOnVector(v: Vector3): Vector3 {
        var scalar = v.dot(this) / v.lengthSq();
        return this.copy(v).multiplyScalar(scalar);
    }

    public function projectOnPlane(planeNormal: Vector3): Vector3 {
        _vector.copy(this).projectOnVector(planeNormal);
        return this.sub(_vector);
    }

    public function reflect(normal: Vector3): Vector3 {
        // reflect incident vector off plane orthogonal to normal
        // normal is assumed to have unit length
        return this.sub(_vector.copy(normal).multiplyScalar(2 * this.dot(normal)));
    }

    public function angleTo(v: Vector3): Float {
        var denominator = Math.sqrt(this.lengthSq() * v.lengthSq());
        if (denominator == 0) return Math.PI / 2;
        var theta = this.dot(v) / denominator;
        // clamp, to handle numerical problems
        return Math.acos(Math.max(-1, Math.min(1, theta)));
    }

    public function distanceTo(v: Vector3): Float {
        return Math.sqrt(this.distanceToSquared(v));
    }

    public function distanceToSquared(v: Vector3): Float {
        var dx = this.x - v.x;
        var dy = this.y - v.y;
        var dz = this.z - v.z;
        return dx * dx + dy * dy + dz * dz;
    }

    public function manhattanDistanceTo(v: Vector3): Float {
        return Math.abs(this.x - v.x) + Math.abs(this.y - v.y) + Math.abs(this.z - v.z);
    }

    public function setFromSpherical(s: Spherical): Vector3 {
        return this.setFromSphericalCoords(s.radius, s.phi, s.theta);
    }

    public function setFromSphericalCoords(radius: Float, phi: Float, theta: Float): Vector3 {
        var sinPhiRadius = Math.sin(phi) * radius;
        this.x = sinPhiRadius * Math.sin(theta);
        this.y = Math.cos(phi) * radius;
        this.z = sinPhiRadius * Math.cos(theta);
        return this;
    }

    public function setFromCylindrical(c: Cylindrical): Vector3 {
        return this.setFromCylindricalCoords(c.radius, c.theta, c.y);
    }

    public function setFromCylindricalCoords(radius: Float, theta: Float, y: Float): Vector3 {
        this.x = radius * Math.sin(theta);
        this.y = y;
        this.z = radius * Math.cos(theta);
        return this;
    }

    public function setFromMatrixPosition(m: Matrix4): Vector3 {
        var e = m.elements;
        this.x = e[12];
        this.y = e[13];
        this.z = e[14];
        return this;
    }

    public function setFromMatrixScale(m: Matrix4): Vector3 {
        var sx = this.setFromMatrixColumn(m, 0).length();
        var sy = this.setFromMatrixColumn(m, 1).length();
        var sz = this.setFromMatrixColumn(m, 2).length();
        this.x = sx;
        this.y = sy;
        this.z = sz;
        return this;
    }

    public function setFromMatrixColumn(m: Matrix4, index: Int): Vector3 {
        return this.fromArray(m.elements, index * 4);
    }

    public function setFromMatrix3Column(m: Matrix3, index: Int): Vector3 {
        return this.fromArray(m.elements, index * 3);
    }

    public function fromArray(array: Array<Float>, offset: Int = 0): Vector3 {
        this.x = array[offset];
        this.y = array[offset + 1];
        this.z = array[offset + 2];
        return this;
    }

    public function toArray(array: Array<Float> = null, offset: Int = 0): Array<Float> {
        if (array == null) array = [];
        array[offset] = this.x;
        array[offset + 1] = this.y;
        array[offset + 2] = this.z;
        return array;
    }

    public function fromBufferAttribute(attribute: BufferAttribute, index: Int): Vector3 {
        this.x = attribute.getX(index);
        this.y = attribute.getY(index);
        this.z = attribute.getZ(index);
        return this;
    }

    public function random(): Vector3 {
        this.x = Math.random();
        this.y = Math.random();
        this.z = Math.random();
        return this;
    }

    public function randomDirection(): Vector3 {
        // Derived from https://mathworld.wolfram.com/SpherePointPicking.html
        var u = (Math.random() - 0.5) * 2;
        var t = Math.random() * Math.PI * 2;
        var f = Math.sqrt(1 - u ** 2);
        this.x = f * Math.cos(t);
        this.y = f * Math.sin(t);
        this.z = u;
        return this;
    }

    private static var _quaternion: Quaternion = new Quaternion();
    private static var _vector: Vector3 = new Vector3();

    public static function fromArray(array: Array<Float>, offset: Int = 0): Vector3 {
        return new Vector3().fromArray(array, offset);
    }

    public static function toArray(vector: Vector3, array: Array<Float> = null, offset: Int = 0): Array<Float> {
        return vector.toArray(array, offset);
    }
}