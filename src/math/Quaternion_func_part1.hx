Here is the equivalent Haxe code for the provided JavaScript code:
```
package three.math;

import Math;

class Quaternion {
    public var _x:Float;
    public var _y:Float;
    public var _z:Float;
    public var _w:Float;
    public var isQuaternion:Bool;

    public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1) {
        _x = x;
        _y = y;
        _z = z;
        _w = w;
        isQuaternion = true;
    }

    public static function slerpFlat(dst:Array<Float>, dstOffset:Int, src0:Array<Float>, srcOffset0:Int, src1:Array<Float>, srcOffset1:Int, t:Float) {
        // fuzz-free, array-based Quaternion SLERP operation
        var x0:Float = src0[srcOffset0 + 0];
        var y0:Float = src0[srcOffset0 + 1];
        var z0:Float = src0[srcOffset0 + 2];
        var w0:Float = src0[srcOffset0 + 3];

        var x1:Float = src1[srcOffset1 + 0];
        var y1:Float = src1[srcOffset1 + 1];
        var z1:Float = src1[srcOffset1 + 2];
        var w1:Float = src1[srcOffset1 + 3];

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
            var s:Float = 1 - t;
            var cos:Float = x0 * x1 + y0 * y1 + z0 * z1 + w0 * w1,
                dir:Float = (cos >= 0 ? 1 : -1),
                sqrSin:Float = 1 - cos * cos;

            if (sqrSin > Math.EPSILON) {
                var sin:Float = Math.sqrt(sqrSin),
                    len:Float = Math.atan2(sin, cos * dir);

                s = Math.sin(s * len) / sin;
                t = Math.sin(t * len) / sin;

            }

            var tDir:Float = t * dir;

            x0 = x0 * s + x1 * tDir;
            y0 = y0 * s + y1 * tDir;
            z0 = z0 * s + z1 * tDir;
            w0 = w0 * s + w1 * tDir;

            if (s == 1 - t) {
                var f:Float = 1 / Math.sqrt(x0 * x0 + y0 * y0 + z0 * z0 + w0 * w0);

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
        var x0:Float = src0[srcOffset0];
        var y0:Float = src0[srcOffset0 + 1];
        var z0:Float = src0[srcOffset0 + 2];
        var w0:Float = src0[srcOffset0 + 3];

        var x1:Float = src1[srcOffset1];
        var y1:Float = src1[srcOffset1 + 1];
        var z1:Float = src1[srcOffset1 + 2];
        var w1:Float = src1[srcOffset1 + 3];

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

    public function set(x:Float, y:Float, z:Float, w:Float) {
        _x = x;
        _y = y;
        _z = z;
        _w = w;

        _onChangeCallback();
    }

    public function clone():Quaternion {
        return new Quaternion(_x, _y, _z, _w);
    }

    public function copy(quaternion:Quaternion) {
        _x = quaternion.x;
        _y = quaternion.y;
        _z = quaternion.z;
        _w = quaternion.w;

        _onChangeCallback();
    }

    public function setFromEuler(euler:Euler, update:Bool = true) {
        var x:Float = euler.x, y:Float = euler.y, z:Float = euler.z, order:String = euler.order;

        var cos:Float = Math.cos;
        var sin:Float = Math.sin;

        var c1:Float = cos(x / 2);
        var c2:Float = cos(y / 2);
        var c3:Float = cos(z / 2);

        var s1:Float = sin(x / 2);
        var s2:Float = sin(y / 2);
        var s3:Float = sin(z / 2);

        switch (order) {
            case 'XYZ':
                _x = s1 * c2 * c3 + c1 * s2 * s3;
                _y = c1 * s2 * c3 - s1 * c2 * s3;
                _z = c1 * c2 * s3 + s1 * s2 * c3;
                _w = c1 * c2 * c3 - s1 * s2 * s3;
                break;
            case 'YXZ':
                _x = s1 * c2 * c3 + c1 * s2 * s3;
                _y = c1 * s2 * c3 - s1 * c2 * s3;
                _z = c1 * c2 * s3 - s1 * s2 * c3;
                _w = c1 * c2 * c3 + s1 * s2 * s3;
                break;
            case 'ZXY':
                _x = s1 * c2 * c3 - c1 * s2 * s3;
                _y = c1 * s2 * c3 + s1 * c2 * s3;
                _z = c1 * c2 * s3 + s1 * s2 * c3;
                _w = c1 * c2 * c3 - s1 * s2 * s3;
                break;
            case 'ZYX':
                _x = s1 * c2 * c3 - c1 * s2 * s3;
                _y = c1 * s2 * c3 + s1 * c2 * s3;
                _z = c1 * c2 * s3 - s1 * s2 * c3;
                _w = c1 * c2 * c3 + s1 * s2 * s3;
                break;
            case 'YZX':
                _x = s1 * c2 * c3 + c1 * s2 * s3;
                _y = c1 * s2 * c3 + s1 * c2 * s3;
                _z = c1 * c2 * s3 - s1 * s2 * c3;
                _w = c1 * c2 * c3 - s1 * s2 * s3;
                break;
            case 'XZY':
                _x = s1 * c2 * c3 - c1 * s2 * s3;
                _y = c1 * s2 * c3 - s1 * c2 * s3;
                _z = c1 * c2 * s3 + s1 * s2 * c3;
                _w = c1 * c2 * c3 + s1 * s2 * s3;
                break;
            default:
                Console.warn('THREE.Quaternion: .setFromEuler() encountered an unknown order: ' + order);
        }

        if (update) _onChangeCallback();

        return this;
    }

    public function setFromAxisAngle(axis:Vector3, angle:Float) {
        var halfAngle:Float = angle / 2, s:Float = Math.sin(halfAngle);

        _x = axis.x * s;
        _y = axis.y * s;
        _z = axis.z * s;
        _w = Math.cos(halfAngle);

        _onChangeCallback();

        return this;
    }

    public function setFromRotationMatrix(m:Array<Float>) {
        var te:Array<Float> = m;

        var m11:Float = te[0];
        var m12:Float = te[4];
        var m13:Float = te[8];
        var m21:Float = te[1];
        var m22:Float = te[5];
        var m23:Float = te[9];
        var m31:Float = te[2];
        var m32:Float = te[6];
        var m33:Float = te[10];

        var trace:Float = m11 + m22 + m33;

        if (trace > 0) {
            var s:Float = 0.5 / Math.sqrt(trace + 1.0);

            _w = 0.25 / s;
            _x = (m32 - m23) * s;
            _y = (m13 - m31) * s;
            _z = (m21 - m12) * s;
        } else if (m11 > m22 && m11 > m33) {
            var s:Float = 2.0 * Math.sqrt(1.0 + m11 - m22 - m33);

            _w = (m32 - m23) / s;
            _x = 0.25 * s;
            _y = (m12 + m21) / s;
            _z = (m13 + m31) / s;
        } else if (m22 > m33) {
            var s:Float = 2.0 * Math.sqrt(1.0 + m22 - m11 - m33);

            _w = (m13 - m31) / s;
            _x = (m12 + m21) / s;
            _y = 0.25 * s;
            _z = (m23 + m32) / s;
        } else {
            var s:Float = 2.0 * Math.sqrt(1.0 + m33 - m11 - m22);

            _w = (m21 - m12) / s;
            _x = (m13 + m31) / s;
            _y = (m23 + m32) / s;
            _z = 0.25 * s;
        }

        _onChangeCallback();

        return this;
    }

    public function setFromUnitVectors(vFrom:Vector3, vTo:Vector3) {
        var r:Float = vFrom.dot(vTo) + 1;

        if (r < Math.EPSILON) {
            _x = -vFrom.y;
            _y = vFrom.x;
            _z = 0;
            _w = r;
        } else {
            _x = vFrom.y * vTo.z - vFrom.z * vTo.y;
            _y = vFrom.z * vTo.x - vFrom.x * vTo.z;
            _z = vFrom.x * vTo.y - vFrom.y * vTo.x;
            _w = r;
        }

        return this.normalize();
    }

    public function angleTo(q:Quaternion) {
        return 2 * Math.acos(Math.abs(MathUtils.clamp(this.dot(q), -1, 1)));
    }

    public function rotateTowards(q:Quaternion, step:Float) {
        var angle:Float = this.angleTo(q);

        if (angle == 0) return this;

        var t:Float = Math.min(1, step / angle);

        this.slerp(q, t);

        return this;
    }

    public function identity() {
        return this.set(0, 0, 0, 1);
    }

    public function invert() {
        _x *= -1;
        _y *= -1;
        _z *= -1;

        _onChangeCallback();

        return this;
    }

    public function conjugate() {
        _x *= -1;
        _y *= -1;
        _z *= -1;

        _onChangeCallback();

        return this;
    }

    public function dot(v:Quaternion) {
        return _x * v.x + _y * v.y + _z * v.z + _w * v.w;
    }

    public function lengthSq() {
        return _x * _x + _y * _y + _z * _z + _w * _w;
    }

    public function length() {
        return Math.sqrt(lengthSq());
    }

    public function normalize() {
        var l:Float = length();

        if (l == 0) {
            _x = 0;
            _y = 0;
            _z = 0;
            _w = 1;
        } else {
            l = 1 / l;
            _x *= l;
            _y *= l;
            _z *= l;
            _w *= l;
        }

        _onChangeCallback();

        return this;
    }

    public function multiply(q:Quaternion) {
        return multiplyQuaternions(this, q);
    }

    public function premultiply(q:Quaternion) {
        return multiplyQuaternions(q, this);
    }

    public static function multiplyQuaternions(a:Quaternion, b:Quaternion) {
        var qax:Float = a.x, qay:Float = a.y, qaz:Float = a.z, qaw:Float = a.w;
        var qbx:Float = b.x, qby:Float = b.y, qbz:Float = b.z, qbw:Float = b.w;

        _x = qax * qbw + qaw * qbx + qay * qbz - qaz * q