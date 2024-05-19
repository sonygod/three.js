package three.math;

import js.Math;

class Quaternion {

    public var _x:Float;
    public var _y:Float;
    public var _z:Float;
    public var _w:Float;
    public var isQuaternion:Bool;

    public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
        this._x = x;
        this._y = y;
        this._z = z;
        this._w = w;
        this.isQuaternion = true;
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
        return this;
    }

    public function setFromAxisAngle(axis:Vector3, angle:Float):Quaternion {
        // ...
        return this;
    }

    public function setFromRotationMatrix(m:Matrix4):Quaternion {
        // ...
        return this;
    }

    public function setFromUnitVectors(vFrom:Vector3, vTo:Vector3):Quaternion {
        // ...
        return this;
    }

    public function angleTo(q:Quaternion):Float {
        // ...
        return 0;
    }

    public function rotateTowards(q:Quaternion, step:Float):Quaternion {
        // ...
        return this;
    }

    public function identity():Quaternion {
        // ...
        return this;
    }

    public function invert():Quaternion {
        // ...
        return this;
    }

    public function conjugate():Quaternion {
        // ...
        return this;
    }

    public function dot(v:Quaternion):Float {
        // ...
        return 0;
    }

    public function lengthSq():Float {
        // ...
        return 0;
    }

    public function length():Float {
        // ...
        return 0;
    }

    public function normalize():Quaternion {
        // ...
        return this;
    }

    public function multiply(q:Quaternion):Quaternion {
        // ...
        return this;
    }

    public function premultiply(q:Quaternion):Quaternion {
        // ...
        return this;
    }

    public function multiplyQuaternions(a:Quaternion, b:Quaternion):Quaternion {
        // ...
        return this;
    }

    public function slerp(qb:Quaternion, t:Float):Quaternion {
        // ...
        return this;
    }

    public function slerpQuaternions(qa:Quaternion, qb:Quaternion, t:Float):Quaternion {
        // ...
        return this;
    }

    public function random():Quaternion {
        // ...
        return this;
    }

    public function equals(quaternion:Quaternion):Bool {
        // ...
        return false;
    }

    public function fromArray(array:Array<Float>, offset:Int = 0):Quaternion {
        // ...
        return this;
    }

    public function toArray(array:Array<Float> = [], offset:Int = 0):Array<Float> {
        // ...
        return array;
    }

    public function fromBufferAttribute(attribute:BufferAttribute, index:Int):Quaternion {
        // ...
        return this;
    }

    public function toJSON():Array<Float> {
        // ...
        return [];
    }

    public function _onChange(callback:Void->Void):Quaternion {
        // ...
        return this;
    }

    public function _onChangeCallback():Void {
        // ...
    }

    public function iterator():Iterator<Float> {
        // ...
        return null;
    }
}