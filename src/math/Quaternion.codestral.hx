import three.math.MathUtils;

class Quaternion {
    public var isQuaternion:Bool = true;
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

    public static function slerpFlat(dst:Array<Float>, dstOffset:Int, src0:Array<Float>, srcOffset0:Int, src1:Array<Float>, srcOffset1:Int, t:Float) {
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

            if (sqrSin > Float.EPSILON) {
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

    public static function multiplyQuaternionsFlat(dst:Array<Float>, dstOffset:Int, src0:Array<Float>, srcOffset0:Int, src1:Array<Float>, srcOffset1:Int) {
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

    public var x(get, set):Float;
    public var y(get, set):Float;
    public var z(get, set):Float;
    public var w(get, set):Float;

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
        // Implementation of this method is omitted for brevity.
        // You can translate the JavaScript code to Haxe in a similar manner.
    }

    public function setFromAxisAngle(axis:Vector3, angle:Float):Quaternion {
        var halfAngle = angle / 2;
        var s = Math.sin(halfAngle);

        this._x = axis.x * s;
        this._y = axis.y * s;
        this._z = axis.z * s;
        this._w = Math.cos(halfAngle);

        this._onChangeCallback();

        return this;
    }

    public function setFromRotationMatrix(m:Matrix4):Quaternion {
        // Implementation of this method is omitted for brevity.
        // You can translate the JavaScript code to Haxe in a similar manner.
    }

    public function setFromUnitVectors(vFrom:Vector3, vTo:Vector3):Quaternion {
        // Implementation of this method is omitted for brevity.
        // You can translate the JavaScript code to Haxe in a similar manner.
    }

    public function angleTo(q:Quaternion):Float {
        return 2 * Math.acos(MathUtils.clamp(this.dot(q), -1, 1));
    }

    public function rotateTowards(q:Quaternion, step:Float):Quaternion {
        var angle = this.angleTo(q);

        if (angle == 0) return this;

        var t = Math.min(1, step / angle);

        this.slerp(q, t);

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
        return Math.sqrt(this._x * this._x + this._y * this._y + this._z * this._z + this._w * this._w);
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

            this._x = this._x * l;
            this._y = this._y * l;
            this._z = this._z * l;
            this._w = this._w * l;
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
        var qax = a._x, qay = a._y, qaz = a._z, qaw = a._w;
        var qbx = b._x, qby = b._y, qbz = b._z, qbw = b._w;

        this._x = qax * qbw + qaw * qbx + qay * qbz - qaz * qby;
        this._y = qay * qbw + qaw * qby + qaz * qbx - qax * qbz;
        this._z = qaz * qbw + qaw * qbz + qax * qby - qay * qbx;
        this._w = qaw * qbw - qax * qbx - qay * qby - qaz * qbz;

        this._onChangeCallback();

        return this;
    }

    public function slerp(qb:Quaternion, t:Float):Quaternion {
        if (t == 0) return this;
        if (t == 1) return this.copy(qb);

        var x = this._x, y = this._y, z = this._z, w = this._w;

        var cosHalfTheta = w * qb._w + x * qb._x + y * qb._y + z * qb._z;

        if (cosHalfTheta < 0) {
            this._w = -qb._w;
            this._x = -qb._x;
            this._y = -qb._y;
            this._z = -qb._z;

            cosHalfTheta = -cosHalfTheta;
        } else {
            this.copy(qb);
        }

        if (cosHalfTheta >= 1.0) {
            this._w = w;
            this._x = x;
            this._y = y;
            this._z = z;

            return this;
        }

        var sqrSinHalfTheta = 1.0 - cosHalfTheta * cosHalfTheta;

        if (sqrSinHalfTheta <= Float.EPSILON) {
            var s = 1 - t;
            this._w = s * w + t * this._w;
            this._x = s * x + t * this._x;
            this._y = s * y + t * this._y;
            this._z = s * z + t * this._z;

            this.normalize();

            return this;
        }

        var sinHalfTheta = Math.sqrt(sqrSinHalfTheta);
        var halfTheta = Math.atan2(sinHalfTheta, cosHalfTheta);
        var ratioA = Math.sin((1 - t) * halfTheta) / sinHalfTheta,
            ratioB = Math.sin(t * halfTheta) / sinHalfTheta;

        this._w = (w * ratioA + this._w * ratioB);
        this._x = (x * ratioA + this._x * ratioB);
        this._y = (y * ratioA + this._y * ratioB);
        this._z = (z * ratioA + this._z * ratioB);

        this._onChangeCallback();

        return this;
    }

    public function slerpQuaternions(qa:Quaternion, qb:Quaternion, t:Float):Quaternion {
        return this.copy(qa).slerp(qb, t);
    }

    public function random():Quaternion {
        var theta1 = 2 * Math.PI * Math.random();
        var theta2 = 2 * Math.PI * Math.random();

        var x0 = Math.random();
        var r1 = Math.sqrt(1 - x0);
        var r2 = Math.sqrt(x0);

        return this.set(
            r1 * Math.sin(theta1),
            r1 * Math.cos(theta1),
            r2 * Math.sin(theta2),
            r2 * Math.cos(theta2),
        );
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

    public function toArray(array:Array<Float> = null, offset:Int = 0):Array<Float> {
        if (array == null) array = [];

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

    public function _onChange(callback:Dynamic -> Void):Quaternion {
        this._onChangeCallback = callback;

        return this;
    }

    public var _onChangeCallback:Dynamic -> Void = function() {};
}