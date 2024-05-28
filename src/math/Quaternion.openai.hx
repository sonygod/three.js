package three.math;

import haxe.ds.Vector;

class Quaternion {
    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var w:Float;

    public function new(x = 0, y = 0, z = 0, w = 1) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    public static function slerpFlat(dst:Array<Float>, dstOffset:Int, src0:Array<Float>, srcOffset0:Int, src1:Array<Float>, srcOffset1:Int, t:Float) {
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
            var cos:Float = x0 * x1 + y0 * y1 + z0 * z1 + w0 * w1;
            var dir:Float = (cos >= 0 ? 1 : -1);
            var sqrSin:Float = 1 - cos * cos;

            if (sqrSin > Math.EPSILON) {
                var sin:Float = Math.sqrt(sqrSin);
                var len:Float = Math.atan2(sin, cos * dir);

                s = Math.sin(s * len) / sin;
                t = Math.sin(t * len) / sin;

                x0 = x0 * s + x1 * t * dir;
                y0 = y0 * s + y1 * t * dir;
                z0 = z0 * s + z1 * t * dir;
                w0 = w0 * s + w1 * t * dir;
            }

            // Normalize in case we just did a lerp:
            if (s == 1 - t) {
                var f:Float = 1 / Math.sqrt(x0 * x0 + y0 * y0 + z0 * z0 + w0 * w0);

                x0 *= f;
                y0 *= f;
                z0 *= f;
                w0 *= f;
            }

            dst[dstOffset + 0] = x0;
            dst[dstOffset + 1] = y0;
            dst[dstOffset + 2] = z0;
            dst[dstOffset + 3] = w0;
        }
    }

    public static function multiplyQuaternionsFlat(dst:Array<Float>, dstOffset:Int, src0:Array<Float>, srcOffset0:Int, src1:Array<Float>, srcOffset1:Int) {
        var x0:Float = src0[srcOffset0 + 0];
        var y0:Float = src0[srcOffset0 + 1];
        var z0:Float = src0[srcOffset0 + 2];
        var w0:Float = src0[srcOffset0 + 3];

        var x1:Float = src1[srcOffset1 + 0];
        var y1:Float = src1[srcOffset1 + 1];
        var z1:Float = src1[srcOffset1 + 2];
        var w1:Float = src1[srcOffset1 + 3];

        dst[dstOffset + 0] = x0 * w1 + w0 * x1 + y0 * z1 - z0 * y1;
        dst[dstOffset + 1] = y0 * w1 + w0 * y1 + z0 * x1 - x0 * z1;
        dst[dstOffset + 2] = z0 * w1 + w0 * z1 + x0 * y1 - y0 * x1;
        dst[dstOffset + 3] = w0 * w1 - x0 * x1 - y0 * y1 - z0 * z1;
    }

    public var onChangeCallback:Void->Void;

    public function set(x:Float, y:Float, z:Float, w:Float) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
        onChangeCallback();
        return this;
    }

    public function clone():Quaternion {
        return new Quaternion(x, y, z, w);
    }

    // ... rest of the class implementation
}