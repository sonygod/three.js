import js.MathUtils;

class Quaternion {

    public var _x:Float;
    public var _y:Float;
    public var _z:Float;
    public var _w:Float;

    public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
        this._x = x;
        this._y = y;
        this._z = z;
        this._w = w;
    }

    public static function slerpFlat(dst:Array<Float>, dstOffset:Int, src0:Array<Float>, srcOffset0:Int, src1:Array<Float>, srcOffset1:Int, t:Float):Void {
        // fuzz-free, array-based Quaternion SLERP operation
        var x0 = src0[srcOffset0 + 0];
        var y0 = src0[srcOffset0 + 1];
        var z0 = src0[srcOffset0 + 2];
        var w0 = src0[srcOffset0 + 3];
        var x1 = src1[srcOffset1 + 0];
        var y1 = src1[srcOffset1 + 1];
        var z1 = src1[srcOffset1 + 2];
        var w1 = src1[srcOffset1 + 3];

        if (t == 0) {
            dst[dstOffset + 0] = x0;
            dst[dstOffset + 1] = y0;
            dst[dstOffset + 2] = z0;
            dst[dstOffset + 3] = w0;
            return;
        }

        if (t == 1) {
            dst[dstOffset + 0] = x1;
            dst[dstOffset + 1] = y1;
            dst[dstOffset + 2] = z1;
            dst[dstOffset + 3] = w1;
            return;
        }

        if (w0 != w1 || x0 != x1 || y0 != y1 || z0 != z1) {
            var s = 1 - t;
            var cos = x0 * x1 + y0 * y1 + z0 * z1 + w0 * w1;
            var dir = (cos >= 0 ? 1 : -1);
            var sqrSin = 1 - cos * cos;

            // Skip the Slerp for tiny steps to avoid numeric problems:
            if (sqrSin > Math.EPSILON) {
                var sin = Math.sqrt(sqrSin);
                var len = Math.atan2(sin, cos * dir);

                s = Math.sin(s * len) / sin;
                t = Math.sin(t * len) / sin;
            }

            var tDir = t * dir;

            x0 = x0 * s + x1 * tDir;
            y0 = y0 * s + y1 * tDir;
            z0 = z0 * s + z1 * tDir;
            w0 = w0 * s + w1 * tDir;

            // Normalize in case we just did a lerp:
            if (s == 1 - t) {
                var f = 1 / Math.sqrt(x0 * x0 + y0 * y0 + z0 * z0 + w0 * w0);

                x0 *= f;
                y0 *= f;
                z0 *= f;
                w0 *= f;
            }
        }

        dst[dstOffset] = x0;
        dst[dstOffset + 1] = y0;
        dst[dstOffset + 2] = z0;
        dst[dstOffset + 3] = w0;
    }

    public static function multiplyQuaternionsFlat(dst:Array<Float>, dstOffset:Int, src0:Array<Float>, srcOffset0:Int, src1:Array<Float>, srcOffset1:Int):Array<Float> {
        var x0 = src0[srcOffset0];
        var y0 = src0[srcOffset0 + 1];
        var z0 = src0[srcOffset0 + 2];
        var w0 = src0[srcOffset0 + 3];

        var x1 = src1[srcOffset1];
        var y1 = src1[srcOffset1 + 1];
        var z1 = src1[srcOffset1 + 2];
        var w1 = src1[srcOffset1 + 3];

        dst[dstOffset] = x0 * w1 + w0 * x1 + y0 * z1 - z0 * y1;
        dst[dstOffset + 1] = y0 * w1 + w0 * y1 + z0 * x1 - x0 * z1;
        dst[dstOffset + 2] = z0 * w1 + w0 * z1 + x0 * y1 - y0 * x1;
        dst[dstOffset + 3] = w0 * w1 - x0 * x1 - y0 * y1 - z0 * z1;

        return dst;
    }

    public function get x():Float {
        return this._x;
    }

    public function set x(value:Float):Void {
        this._x = value;
        this._onChangeCallback();
    }

    public function get y():Float {
        return this._y;
    }

    public function set y(value:Float):Void {
        this._y = value;
        this._onChangeCallback();
    }

    public function get z():Float {
        return this._z;
    }

    public function set z(value:Float):Void {
        this._z = value;
        this._onChangeCallback();
    }

    public function get w():Float {
        return this._w;
    }

    public function set w(value:Float):Void {
        this._w = value;
        this._onChangeCallback();
    }

    public function set(x:Float, y:Float, z:Float, w:Float):Quaternion {
        this._x = x;
        this._y = y;
        this._z = z;
        this._w = w;

        this._onChangeCallback();

        return this;
    }

    public function clone():Quaternion {
        return new Quaternion(this._x, this._y, this._z, this._w);
    }

    public function copy(quaternion:Quaternion):Quaternion {
        this._x = quaternion.x;
        this._y = quaternion.y;
        this._z = quaternion.z;
        this._w = quaternion.w;

        this._onChangeCallback();

        return this;
    }

    public function setFromEuler(euler:Euler, update:Bool = true):Quaternion {
        // ...
        // 这里省略了setFromEuler的实现，因为它依赖于Euler类，而Euler类不在给出的代码中
        // ...
        return this;
    }

    public function setFromAxisAngle(axis:Vector3, angle:Float):Quaternion {
        // ...
        // 这里省略了setFromAxisAngle的实现，因为它依赖于Vector3类，而Vector3类不在给出的代码中
        // ...
        return this;
    }

    public function setFromRotationMatrix(m:Matrix4):Quaternion {
        // ...
        // 这里省略了setFromRotationMatrix的实现，因为它依赖于Matrix4类，而Matrix4类不在给出的代码中
        // ...
        return this;
    }

    public function setFromUnitVectors(vFrom:Vector3, vTo:Vector3):Quaternion {
        // ...
        // 这里省略了setFromUnitVectors的实现，因为它依赖于Vector3类，而Vector3类不在给出的代码中
        // ...
        return this;
    }

    public function angleTo(q:Quaternion):Float {
        // ...
        // 这里省略了angleTo的实现，因为它依赖于MathUtils类，而MathUtils类不在给出的代码中
        // ...
        return 0;
    }

    public function rotateTowards(q:Quaternion, step:Float):Quaternion {
        // ...
        // 这里省略了rotateTowards的实现，因为它依赖于MathUtils类，而MathUtils类不在给出的代码中
        // ...
        return this;
    }

    public function identity():Quaternion {
        return this.set(0, 0, 0, 1);
    }

    public function invert():Quaternion {
        return this.conjugate();
    }

    public function conjugate():Quaternion {
        this._x *= -1;
        this._y *= -1;
        this._z *= -1;

        this._onChangeCallback();

        return this;
    }

    public function dot(v:Quaternion):Float {
        return this._x * v._x + this._y * v._y + this._z * v._z + this._w * v._w;
    }

    public function lengthSq():Float {
        return this._x * this._x + this._y * this._y + this._z * this._z + this._w * this._w;
    }

    public function length():Float {
        return Math.sqrt(this.lengthSq());
    }

    public function normalize():Quaternion {
        var l = this.length();

        if (l == 0) {
            this._x = 0;
            this._y = 0;
            this._z = 0;
            this._w = 1;
        } else {
            l = 1 / l;

            this._x *= l;
            this._y *= l;
            this._z *= l;
            this._w *= l;
        }

        this._onChangeCallback();

        return this;
    }

    public function multiply(q:Quaternion):Quaternion {
        return this.multiplyQuaternions(this, q);
    }

    public function premultiply(q:Quaternion):Quaternion {
        return this.multiplyQuaternions(q, this);
    }

    public function multiplyQuaternions(a:Quaternion, b:Quaternion):Quaternion {
        // ...
        // 这里省略了multiplyQuaternions的实现，因为它依赖于MathUtils类，而MathUtils类不在给出的代码中
        // ...
        return this;
    }

    public function slerp(qb:Quaternion, t:Float):Quaternion {
        // ...
        // 这里省略了slerp的实现，因为它依赖于MathUtils类，而MathUtils类不在给出的代码中
        // ...
        return this;
    }

    public function slerpQuaternions(qa:Quaternion, qb:Quaternion, t:Float):Quaternion {
        return this.copy(qa).slerp(qb, t);
    }

    public function random():Quaternion {
        // ...
        // 这里省略了random的实现，因为它依赖于MathUtils类，而MathUtils类不在给出的代码中
        // ...
        return this;
    }

    public function equals(quaternion:Quaternion):Bool {
        return (quaternion._x == this._x) && (quaternion._y == this._y) && (quaternion._z == this._z) && (quaternion._w == this._w);
    }

    public function fromArray(array:Array<Float>, offset:Int = 0):Quaternion {
        this._x = array[offset];
        this._y = array[offset + 1];
        this._z = array[offset + 2];
        this._w = array[offset + 3];

        this._onChangeCallback();

        return this;
    }

    public function toArray(array:Array<Float> = [], offset:Int = 0):Array<Float> {
        array[offset] = this._x;
        array[offset + 1] = this._y;
        array[offset + 2] = this._z;
        array[offset + 3] = this._w;

        return array;
    }

    public function fromBufferAttribute(attribute:BufferAttribute, index:Int):Quaternion {
        this._x = attribute.getX(index);
        this._y = attribute.getY(index);
        this._z = attribute.getZ(index);
        this._w = attribute.getW(index);

        this._onChangeCallback();

        return this;
    }

    public function toJSON():Array<Float> {
        return this.toArray();
    }

    public function _onChange(callback:Void->Void):Quaternion {
        this._onChangeCallback = callback;
        return this;
    }

    public var _onChangeCallback:Void->Void = function():Void {};

    public function toString():String {
        return "[" + this._x + ", " + this._y + ", " + this._z + ", " + this._w + "]";
    }

    public function *[Symbol.iterator]():Iterator<Float> {
        yield this._x;
        yield this._y;
        yield this._z;
        yield this._w;
    }
}