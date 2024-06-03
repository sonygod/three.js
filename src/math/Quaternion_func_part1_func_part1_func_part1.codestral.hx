import MathUtils;

class Quaternion {
    var _x: Float;
    var _y: Float;
    var _z: Float;
    var _w: Float;
    var _onChangeCallback: Void -> Void;

    function new(x: Float = 0, y: Float = 0, z: Float = 0, w: Float = 1) {
        this._x = x;
        this._y = y;
        this._z = z;
        this._w = w;
        this._onChangeCallback = () -> {};
    }

    static function slerpFlat(dst: Array<Float>, dstOffset: Int, src0: Array<Float>, srcOffset0: Int, src1: Array<Float>, srcOffset1: Int, t: Float) {
        var x0 = src0[srcOffset0 + 0];
        var y0 = src0[srcOffset0 + 1];
        var z0 = src0[srcOffset0 + 2];
        var w0 = src0[srcOffset0 + 3];

        var x1 = src1[srcOffset1 + 0];
        var y1 = src1[srcOffset1 + 1];
        var z1 = src1[srcOffset1 + 2];
        var w1 = src1[srcOffset1 + 3];

        if (t === 0) {
            dst[dstOffset + 0] = x0;
            dst[dstOffset + 1] = y0;
            dst[dstOffset + 2] = z0;
            dst[dstOffset + 3] = w0;
            return;
        }

        if (t === 1) {
            dst[dstOffset + 0] = x1;
            dst[dstOffset + 1] = y1;
            dst[dstOffset + 2] = z1;
            dst[dstOffset + 3] = w1;
            return;
        }

        if (w0 !== w1 || x0 !== x1 || y0 !== y1 || z0 !== z1) {
            var s = 1 - t;
            var cos = x0 * x1 + y0 * y1 + z0 * z1 + w0 * w1;
            var dir = cos >= 0 ? 1 : -1;
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

            if (s === 1 - t) {
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

    static function multiplyQuaternionsFlat(dst: Array<Float>, dstOffset: Int, src0: Array<Float>, srcOffset0: Int, src1: Array<Float>, srcOffset1: Int): Array<Float> {
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

    function get x(): Float {
        return this._x;
    }

    function set x(value: Float) {
        this._x = value;
        this._onChangeCallback();
    }

    // similar getter/setter for y, z, w

    function set(x: Float, y: Float, z: Float, w: Float): Quaternion {
        this._x = x;
        this._y = y;
        this._z = z;
        this._w = w;

        this._onChangeCallback();

        return this;
    }

    function clone(): Quaternion {
        return new Quaternion(this._x, this._y, this._z, this._w);
    }

    function copy(quaternion: Quaternion): Quaternion {
        this._x = quaternion.x;
        this._y = quaternion.y;
        this._z = quaternion.z;
        this._w = quaternion.w;

        this._onChangeCallback();

        return this;
    }

    // rest of the functions can be implemented similarly
}