package three.math;

import haxe.ds.Vector;

class Vector4 {
    public var x:Float = 0;
    public var y:Float = 0;
    public var z:Float = 0;
    public var w:Float = 1;

    public function new(?x:Float = 0, ?y:Float = 0, ?z:Float = 0, ?w:Float = 1) {
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
        return z;
    }

    public var height(get, set):Float;
    private function get_height():Float {
        return w;
    }
    private function set_height(value:Float):Float {
        w = value;
        return w;
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
            case 0:
                x = value;
            case 1:
                y = value;
            case 2:
                z = value;
            case 3:
                w = value;
            default:
                throw new Error('index is out of range: ' + index);
        }
        return this;
    }

    public function getComponent(index:Int):Float {
        switch (index) {
            case 0:
                return x;
            case 1:
                return y;
            case 2:
                return z;
            case 3:
                return w;
            default:
                throw new Error('index is out of range: ' + index);
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

    public function multiplyScalar(scalar:Float):Vector4 {
        x *= scalar;
        y *= scalar;
        z *= scalar;
        w *= scalar;
        return this;
    }

    public function applyMatrix4(m:Array<Float>):Vector4 {
        var e:Array<Float> = m;
        var x1:Float = x;
        var y1:Float = y;
        var z1:Float = z;
        var w1:Float = w;
        x = e[0] * x1 + e[4] * y1 + e[8] * z1 + e[12] * w1;
        y = e[1] * x1 + e[5] * y1 + e[9] * z1 + e[13] * w1;
        z = e[2] * x1 + e[6] * y1 + e[10] * z1 + e[14] * w1;
        w = e[3] * x1 + e[7] * y1 + e[11] * z1 + e[15] * w1;
        return this;
    }

    public function divideScalar(scalar:Float):Vector4 {
        return multiplyScalar(1 / scalar);
    }

    public function setAxisAngleFromQuaternion(q:Array<Float>):Vector4 {
        w = 2 * Math.acos(q[3]);
        var s:Float = Math.sqrt(1 - q[3] * q[3]);
        if (s < 0.0001) {
            x = 1;
            y = 0;
            z = 0;
        } else {
            x = q[0] / s;
            y = q[1] / s;
            z = q[2] / s;
        }
        return this;
    }

    public function setAxisAngleFromRotationMatrix(m:Array<Float>):Vector4 {
        // ...
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
        return divideScalar(length || 1).multiplyScalar(Math.max(min, Math.min(max, length)));
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

    public function fromBufferAttribute(attribute:Array<Float>, index:Int):Vector4 {
        x = attribute[index];
        y = attribute[index + 1];
        z = attribute[index + 2];
        w = attribute[index + 3];
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
        return new VectorIterator([x, y, z, w]);
    }
}

class VectorIterator implements Iterator<Float> {
    var vector:Array<Float>;

    public function new(vector:Array<Float>) {
        this.vector = vector;
    }

    public function hasNext():Bool {
        return vector.length > 0;
    }

    public function next():Float {
        return vector.shift();
    }
}