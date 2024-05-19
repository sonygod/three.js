package three.math;

class Vector4 {
    public var x:Float = 0;
    public var y:Float = 0;
    public var z:Float = 0;
    public var w:Float = 1;

    public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    public var width(get, set):Float;
    private function get_width():Float {
        return z;
    }
    private function set_width(value:Float):Float {
        z = value;
        return value;
    }

    public var height(get, set):Float;
    private function get_height():Float {
        return w;
    }
    private function set_height(value:Float):Float {
        w = value;
        return value;
    }

    public function set(x:Float, y:Float, z:Float, w:Float):Vector4 {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
        return this;
    }

    public function setScalar(scalar:Float):Vector4 {
        x = scalar;
        y = scalar;
        z = scalar;
        w = scalar;
        return this;
    }

    public function setX(x:Float):Vector4 {
        this.x = x;
        return this;
    }

    public function setY(y:Float):Vector4 {
        this.y = y;
        return this;
    }

    public function setZ(z:Float):Vector4 {
        this.z = z;
        return this;
    }

    public function setW(w:Float):Vector4 {
        this.w = w;
        return this;
    }

    public function setComponent(index:Int, value:Float):Vector4 {
        switch (index) {
            case 0: x = value;
            case 1: y = value;
            case 2: z = value;
            case 3: w = value;
            default: throw new Error('index is out of range: ' + index);
        }
        return this;
    }

    public function getComponent(index:Int):Float {
        switch (index) {
            case 0: return x;
            case 1: return y;
            case 2: return z;
            case 3: return w;
            default: throw new Error('index is out of range: ' + index);
        }
    }

    public function clone():Vector4 {
        return new Vector4(x, y, z, w);
    }

    public function copy(v:Vector4):Vector4 {
        x = v.x;
        y = v.y;
        z = v.z;
        w = v.w;
        return this;
    }

    public function add(v:Vector4):Vector4 {
        x += v.x;
        y += v.y;
        z += v.z;
        w += v.w;
        return this;
    }

    public function addScalar(s:Float):Vector4 {
        x += s;
        y += s;
        z += s;
        w += s;
        return this;
    }

    public function addVectors(a:Vector4, b:Vector4):Vector4 {
        x = a.x + b.x;
        y = a.y + b.y;
        z = a.z + b.z;
        w = a.w + b.w;
        return this;
    }

    public function addScaledVector(v:Vector4, s:Float):Vector4 {
        x += v.x * s;
        y += v.y * s;
        z += v.z * s;
        w += v.w * s;
        return this;
    }

    public function sub(v:Vector4):Vector4 {
        x -= v.x;
        y -= v.y;
        z -= v.z;
        w -= v.w;
        return this;
    }

    public function subScalar(s:Float):Vector4 {
        x -= s;
        y -= s;
        z -= s;
        w -= s;
        return this;
    }

    public function subVectors(a:Vector4, b:Vector4):Vector4 {
        x = a.x - b.x;
        y = a.y - b.y;
        z = a.z - b.z;
        w = a.w - b.w;
        return this;
    }

    public function multiply(v:Vector4):Vector4 {
        x *= v.x;
        y *= v.y;
        z *= v.z;
        w *= v.w;
        return this;
    }

    public function multiplyScalar(s:Float):Vector4 {
        x *= s;
        y *= s;
        z *= s;
        w *= s;
        return this;
    }

    public function applyMatrix4(m:Array<Float>):Vector4 {
        var e:Array<Float> = m;
        x = e[0] * x + e[4] * y + e[8] * z + e[12] * w;
        y = e[1] * x + e[5] * y + e[9] * z + e[13] * w;
        z = e[2] * x + e[6] * y + e[10] * z + e[14] * w;
        w = e[3] * x + e[7] * y + e[11] * z + e[15] * w;
        return this;
    }

    public function divideScalar(s:Float):Vector4 {
        return multiplyScalar(1 / s);
    }

    public function setAxisAngleFromQuaternion(q:Vector4):Vector4 {
        // http://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToAngle/index.htm
        w = 2 * Math.acos(q.w);
        var s:Float = Math.sqrt(1 - q.w * q.w);
        if (s < 0.0001) {
            x = 1;
            y = 0;
            z = 0;
        } else {
            x = q.x / s;
            y = q.y / s;
            z = q.z / s;
        }
        return this;
    }

    public function setAxisAngleFromRotationMatrix(m:Array<Float>):Vector4 {
        // http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToAngle/index.htm
        var te:Array<Float> = m;
        var m11:Float = te[0], m12:Float = te[4], m13:Float = te[8],
            m21:Float = te[1], m22:Float = te[5], m23:Float = te[9],
            m31:Float = te[2], m32:Float = te[6], m33:Float = te[10];

        if (Math.abs(m12 - m21) < 0.01 && Math.abs(m13 - m31) < 0.01 && Math.abs(m23 - m32) < 0.01) {
            // singularity found
            if (Math.abs(m12 + m21) < 0.1 && Math.abs(m13 + m31) < 0.1 && Math.abs(m23 + m32) < 0.1 && Math.abs(m11 + m22 + m33 - 3) < 0.1) {
                // this singularity is identity matrix so angle = 0
                x = 1;
                y = 0;
                z = 0;
                w = 0;
                return this;
            } else {
                // otherwise this singularity is angle = 180
                w = Math.PI;
                var xx:Float = (m11 + 1) / 2;
                var yy:Float = (m22 + 1) / 2;
                var zz:Float = (m33 + 1) / 2;
                var xy:Float = (m12 + m21) / 4;
                var xz:Float = (m13 + m31) / 4;
                var yz:Float = (m23 + m32) / 4;

                if (xx > yy && xx > zz) {
                    // m11 is the largest diagonal term
                    if (xx < 0.01) {
                        x = 0;
                        y = 0.707106781;
                        z = 0.707106781;
                    } else {
                        x = Math.sqrt(xx);
                        y = xy / x;
                        z = xz / x;
                    }
                } else if (yy > zz) {
                    // m22 is the largest diagonal term
                    if (yy < 0.01) {
                        x = 0.707106781;
                        y = 0;
                        z = 0.707106781;
                    } else {
                        y = Math.sqrt(yy);
                        x = xy / y;
                        z = yz / y;
                    }
                } else {
                    // m33 is the largest diagonal term so base result on this
                    if (zz < 0.01) {
                        x = 0.707106781;
                        y = 0.707106781;
                        z = 0;
                    } else {
                        z = Math.sqrt(zz);
                        x = xz / z;
                        y = yz / z;
                    }
                }
                return this;
            }
        }

        // as we have reached here there are no singularities so we can handle normally
        var s:Float = Math.sqrt((m32 - m23) * (m32 - m23) + (m13 - m31) * (m13 - m31) + (m21 - m12) * (m21 - m12));
        if (Math.abs(s) < 0.001) s = 1;
        x = (m32 - m23) / s;
        y = (m13 - m31) / s;
        z = (m21 - m12) / s;
        w = Math.acos((m11 + m22 + m33 - 1) / 2);
        return this;
    }

    public function min(v:Vector4):Vector4 {
        x = Math.min(x, v.x);
        y = Math.min(y, v.y);
        z = Math.min(z, v.z);
        w = Math.min(w, v.w);
        return this;
    }

    public function max(v:Vector4):Vector4 {
        x = Math.max(x, v.x);
        y = Math.max(y, v.y);
        z = Math.max(z, v.z);
        w = Math.max(w, v.w);
        return this;
    }

    public function clamp(min:Vector4, max:Vector4):Vector4 {
        x = Math.max(min.x, Math.min(max.x, x));
        y = Math.max(min.y, Math.min(max.y, y));
        z = Math.max(min.z, Math.min(max.z, z));
        w = Math.max(min.w, Math.min(max.w, w));
        return this;
    }

    public function clampScalar(min:Float, max:Float):Vector4 {
        x = Math.max(min, Math.min(max, x));
        y = Math.max(min, Math.min(max, y));
        z = Math.max(min, Math.min(max, z));
        w = Math.max(min, Math.min(max, w));
        return this;
    }

    public function clampLength(min:Float, max:Float):Vector4 {
        var length:Float = length();
        return multiplyScalar(length > max ? max : length < min ? min : length);
    }

    public function floor():Vector4 {
        x = Math.floor(x);
        y = Math.floor(y);
        z = Math.floor(z);
        w = Math.floor(w);
        return this;
    }

    public function ceil():Vector4 {
        x = Math.ceil(x);
        y = Math.ceil(y);
        z = Math.ceil(z);
        w = Math.ceil(w);
        return this;
    }

    public function round():Vector4 {
        x = Math.round(x);
        y = Math.round(y);
        z = Math.round(z);
        w = Math.round(w);
        return this;
    }

    public function roundToZero():Vector4 {
        x = Math.trunc(x);
        y = Math.trunc(y);
        z = Math.trunc(z);
        w = Math.trunc(w);
        return this;
    }

    public function negate():Vector4 {
        x = -x;
        y = -y;
        z = -z;
        w = -w;
        return this;
    }

    public function dot(v:Vector4):Float {
        return x * v.x + y * v.y + z * v.z + w * v.w;
    }

    public function lengthSq():Float {
        return x * x + y * y + z * z + w * w;
    }

    public function length():Float {
        return Math.sqrt(x * x + y * y + z * z + w * w);
    }

    public function manhattanLength():Float {
        return Math.abs(x) + Math.abs(y) + Math.abs(z) + Math.abs(w);
    }

    public function normalize():Vector4 {
        return divideScalar(length() || 1);
    }

    public function setLength(length:Float):Vector4 {
        return normalize().multiplyScalar(length);
    }

    public function lerp(v:Vector4, alpha:Float):Vector4 {
        x += (v.x - x) * alpha;
        y += (v.y - y) * alpha;
        z += (v.z - z) * alpha;
        w += (v.w - w) * alpha;
        return this;
    }

    public function lerpVectors(v1:Vector4, v2:Vector4, alpha:Float):Vector4 {
        x = v1.x + (v2.x - v1.x) * alpha;
        y = v1.y + (v2.y - v1.y) * alpha;
        z = v1.z + (v2.z - v1.z) * alpha;
        w = v1.w + (v2.w - v1.w) * alpha;
        return this;
    }

    public function equals(v:Vector4):Bool {
        return x == v.x && y == v.y && z == v.z && w == v.w;
    }

    public function fromArray(array:Array<Float>, offset:Int = 0):Vector4 {
        x = array[offset];
        y = array[offset + 1];
        z = array[offset + 2];
        w = array[offset + 3];
        return this;
    }

    public function toArray(array:Array<Float> = [], offset:Int = 0):Array<Float> {
        array[offset] = x;
        array[offset + 1] = y;
        array[offset + 2] = z;
        array[offset + 3] = w;
        return array;
    }

    public function fromBufferAttribute(attribute:Any, index:Int):Vector4 {
        x = attribute.getX(index);
        y = attribute.getY(index);
        z = attribute.getZ(index);
        w = attribute.getW(index);
        return this;
    }

    public function random():Vector4 {
        x = Math.random();
        y = Math.random();
        z = Math.random();
        w = Math.random();
        return this;
    }

    public function iterator():Iterator<Float> {
        return new Vector4Iterator(this);
    }
}

class Vector4Iterator implements Iterator<Float> {
    private var vector:Vector4;
    private var index:Int;

    public function new(vector:Vector4) {
        this.vector = vector;
        this.index = 0;
    }

    public function hasNext():Bool {
        return index < 4;
    }

    public function next():Float {
        return switch (index++) {
            case 0: vector.x;
            case 1: vector.y;
            case 2: vector.z;
            case 3: vector.w;
            default: throw new Error("Index out of range");
        }
    }
}