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
        return this.z;
    }
    private function set_width(value:Float):Float {
        this.z = value;
        return value;
    }

    public var height(get, set):Float;
    private function get_height():Float {
        return this.w;
    }
    private function set_height(value:Float):Float {
        this.w = value;
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
        this.x = scalar;
        this.y = scalar;
        this.z = scalar;
        this.w = scalar;
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
            case 0:
                this.x = value;
            case 1:
                this.y = value;
            case 2:
                this.z = value;
            case 3:
                this.w = value;
            default:
                throw new Error('index is out of range: $index');
        }
        return this;
    }

    public function getComponent(index:Int):Float {
        switch (index) {
            case 0:
                return this.x;
            case 1:
                return this.y;
            case 2:
                return this.z;
            case 3:
                return this.w;
            default:
                throw new Error('index is out of range: $index');
        }
    }

    public function clone():Vector4 {
        return new Vector4(this.x, this.y, this.z, this.w);
    }

    public function copy(v:Vector4):Vector4 {
        this.x = v.x;
        this.y = v.y;
        this.z = v.z;
        this.w = v.w != null ? v.w : 1;
        return this;
    }

    public function add(v:Vector4):Vector4 {
        this.x += v.x;
        this.y += v.y;
        this.z += v.z;
        this.w += v.w;
        return this;
    }

    public function addScalar(s:Float):Vector4 {
        this.x += s;
        this.y += s;
        this.z += s;
        this.w += s;
        return this;
    }

    public function addVectors(a:Vector4, b:Vector4):Vector4 {
        this.x = a.x + b.x;
        this.y = a.y + b.y;
        this.z = a.z + b.z;
        this.w = a.w + b.w;
        return this;
    }

    public function addScaledVector(v:Vector4, s:Float):Vector4 {
        this.x += v.x * s;
        this.y += v.y * s;
        this.z += v.z * s;
        this.w += v.w * s;
        return this;
    }

    public function sub(v:Vector4):Vector4 {
        this.x -= v.x;
        this.y -= v.y;
        this.z -= v.z;
        this.w -= v.w;
        return this;
    }

    public function subScalar(s:Float):Vector4 {
        this.x -= s;
        this.y -= s;
        this.z -= s;
        this.w -= s;
        return this;
    }

    public function subVectors(a:Vector4, b:Vector4):Vector4 {
        this.x = a.x - b.x;
        this.y = a.y - b.y;
        this.z = a.z - b.z;
        this.w = a.w - b.w;
        return this;
    }

    public function multiply(v:Vector4):Vector4 {
        this.x *= v.x;
        this.y *= v.y;
        this.z *= v.z;
        this.w *= v.w;
        return this;
    }

    public function multiplyScalar(s:Float):Vector4 {
        this.x *= s;
        this.y *= s;
        this.z *= s;
        this.w *= s;
        return this;
    }

    public function applyMatrix4(m:Matrix4):Vector4 {
        var e:Array<Float> = m.elements;
        var x:Float = this.x, y:Float = this.y, z:Float = this.z, w:Float = this.w;
        this.x = e[0] * x + e[4] * y + e[8] * z + e[12] * w;
        this.y = e[1] * x + e[5] * y + e[9] * z + e[13] * w;
        this.z = e[2] * x + e[6] * y + e[10] * z + e[14] * w;
        this.w = e[3] * x + e[7] * y + e[11] * z + e[15] * w;
        return this;
    }

    public function divideScalar(s:Float):Vector4 {
        return this.multiplyScalar(1 / s);
    }

    public function setAxisAngleFromQuaternion(q:Quaternion):Vector4 {
        this.w = 2 * Math.acos(q.w);
        var s:Float = Math.sqrt(1 - q.w * q.w);
        if (s < 0.0001) {
            this.x = 1;
            this.y = 0;
            this.z = 0;
        } else {
            this.x = q.x / s;
            this.y = q.y / s;
            this.z = q.z / s;
        }
        return this;
    }

    public function setAxisAngleFromRotationMatrix(m:Matrix4):Vector4 {
        // implementation omitted for brevity
        return this;
    }

    public function min(v:Vector4):Vector4 {
        this.x = Math.min(this.x, v.x);
        this.y = Math.min(this.y, v.y);
        this.z = Math.min(this.z, v.z);
        this.w = Math.min(this.w, v.w);
        return this;
    }

    public function max(v:Vector4):Vector4 {
        this.x = Math.max(this.x, v.x);
        this.y = Math.max(this.y, v.y);
        this.z = Math.max(this.z, v.z);
        this.w = Math.max(this.w, v.w);
        return this;
    }

    public function clamp(min:Vector4, max:Vector4):Vector4 {
        this.x = Math.max(min.x, Math.min(max.x, this.x));
        this.y = Math.max(min.y, Math.min(max.y, this.y));
        this.z = Math.max(min.z, Math.min(max.z, this.z));
        this.w = Math.max(min.w, Math.min(max.w, this.w));
        return this;
    }

    public function clampScalar(min:Float, max:Float):Vector4 {
        this.x = Math.max(min, Math.min(max, this.x));
        this.y = Math.max(min, Math.min(max, this.y));
        this.z = Math.max(min, Math.min(max, this.z));
        this.w = Math.max(min, Math.min(max, this.w));
        return this;
    }

    public function clampLength(min:Float, max:Float):Vector4 {
        var length:Float = this.length();
        return this.divideScalar(length || 1).multiplyScalar(Math.max(min, Math.min(max, length)));
    }

    public function floor():Vector4 {
        this.x = Math.floor(this.x);
        this.y = Math.floor(this.y);
        this.z = Math.floor(this.z);
        this.w = Math.floor(this.w);
        return this;
    }

    public function ceil():Vector4 {
        this.x = Math.ceil(this.x);
        this.y = Math.ceil(this.y);
        this.z = Math.ceil(this.z);
        this.w = Math.ceil(this.w);
        return this;
    }

    public function round():Vector4 {
        this.x = Math.round(this.x);
        this.y = Math.round(this.y);
        this.z = Math.round(this.z);
        this.w = Math.round(this.w);
        return this;
    }

    public function roundToZero():Vector4 {
        this.x = Math.trunc(this.x);
        this.y = Math.trunc(this.y);
        this.z = Math.trunc(this.z);
        this.w = Math.trunc(this.w);
        return this;
    }

    public function negate():Vector4 {
        this.x = -this.x;
        this.y = -this.y;
        this.z = -this.z;
        this.w = -this.w;
        return this;
    }

    public function dot(v:Vector4):Float {
        return this.x * v.x + this.y * v.y + this.z * v.z + this.w * v.w;
    }

    public function lengthSq():Float {
        return this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w;
    }

    public function length():Float {
        return Math.sqrt(this.lengthSq());
    }

    public function manhattanLength():Float {
        return Math.abs(this.x) + Math.abs(this.y) + Math.abs(this.z) + Math.abs(this.w);
    }

    public function normalize():Vector4 {
        return this.divideScalar(this.length() || 1);
    }

    public function setLength(length:Float):Vector4 {
        return this.normalize().multiplyScalar(length);
    }

    public function lerp(v:Vector4, alpha:Float):Vector4 {
        this.x += (v.x - this.x) * alpha;
        this.y += (v.y - this.y) * alpha;
        this.z += (v.z - this.z) * alpha;
        this.w += (v.w - this.w) * alpha;
        return this;
    }

    public function lerpVectors(v1:Vector4, v2:Vector4, alpha:Float):Vector4 {
        this.x = v1.x + (v2.x - v1.x) * alpha;
        this.y = v1.y + (v2.y - v1.y) * alpha;
        this.z = v1.z + (v2.z - v1.z) * alpha;
        this.w = v1.w + (v2.w - v1.w) * alpha;
        return this;
    }

    public function equals(v:Vector4):Bool {
        return this.x == v.x && this.y == v.y && this.z == v.z && this.w == v.w;
    }

    public function fromArray(array:Array<Float>, offset:Int = 0):Vector4 {
        this.x = array[offset];
        this.y = array[offset + 1];
        this.z = array[offset + 2];
        this.w = array[offset + 3];
        return this;
    }

    public function toArray(array:Array<Float> = null, offset:Int = 0):Array<Float> {
        array[offset] = this.x;
        array[offset + 1] = this.y;
        array[offset + 2] = this.z;
        array[offset + 3] = this.w;
        return array;
    }

    public function fromBufferAttribute(attribute:BufferAttribute, index:Int):Vector4 {
        this.x = attribute.getX(index);
        this.y = attribute.getY(index);
        this.z = attribute.getZ(index);
        this.w = attribute.getW(index);
        return this;
    }

    public function random():Vector4 {
        this.x = Math.random();
        this.y = Math.random();
        this.z = Math.random();
        this.w = Math.random();
        return this;
    }

    public iterator():Iterator<Float> {
        return new Vector4Iterator(this);
    }
}

class Vector4Iterator implements Iterator<Float> {
    private var vector:Vector4;
    private var index:Int = 0;

    public function new(vector:Vector4) {
        this.vector = vector;
    }

    public function hasNext():Bool {
        return index < 4;
    }

    public function next():Float {
        var value:Float = switch (index) {
            case 0: vector.x;
            case 1: vector.y;
            case 2: vector.z;
            case 3: vector.w;
            default: throw new Error('Index out of range');
        };
        index++;
        return value;
    }
}