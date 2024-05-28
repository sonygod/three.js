package three.data;

import haxe.io.Bytes;
import haxe.io.Float32Array;
import haxe.io.Int32Array;
import haxe.Math;

class DataUtils {
    private static var _tables:Dynamic;

    static function __init__() {
        _tables = _generateTables();
    }

    private static function _generateTables():Dynamic {
        var buffer = Bytes.alloc(4);
        var floatView = new Float32Array(buffer, 0, 1);
        var uint32View = new Int32Array(buffer, 0, 1);

        var baseTable = new Int32Array(512);
        var shiftTable = new Int32Array(512);

        for (i in 0...256) {
            var e = i - 127;

            // very small number (0, -0)
            if (e < -27) {
                baseTable[i] = 0x0000;
                baseTable[i | 0x100] = 0x8000;
                shiftTable[i] = 24;
                shiftTable[i | 0x100] = 24;

            // small number (denorm)
            } else if (e < -14) {
                baseTable[i] = 0x0400 >> (-e - 14);
                baseTable[i | 0x100] = (0x0400 >> (-e - 14)) | 0x8000;
                shiftTable[i] = -e - 1;
                shiftTable[i | 0x100] = -e - 1;

            // normal number
            } else if (e <= 15) {
                baseTable[i] = (e + 15) << 10;
                baseTable[i | 0x100] = ((e + 15) << 10) | 0x8000;
                shiftTable[i] = 13;
                shiftTable[i | 0x100] = 13;

            // large number (Infinity, -Infinity)
            } else if (e < 128) {
                baseTable[i] = 0x7c00;
                baseTable[i | 0x100] = 0xfc00;
                shiftTable[i] = 24;
                shiftTable[i | 0x100] = 24;

            // stay (NaN, Infinity, -Infinity)
            } else {
                baseTable[i] = 0x7c00;
                baseTable[i | 0x100] = 0xfc00;
                shiftTable[i] = 13;
                shiftTable[i | 0x100] = 13;
            }
        }

        // float16 to float32 helpers

        var mantissaTable = new Int32Array(2048);
        var exponentTable = new Int32Array(64);
        var offsetTable = new Int32Array(64);

        for (i in 1...1024) {
            var m = i << 13; // zero pad mantissa bits
            var e = 0; // zero exponent

            // normalized
            while ((m & 0x00800000) == 0) {
                m <<= 1;
                e -= 0x00800000; // decrement exponent
            }

            m &= ~0x00800000; // clear leading 1 bit
            e += 0x38800000; // adjust bias

            mantissaTable[i] = m | e;
        }

        for (i in 1024...2048) {
            mantissaTable[i] = 0x38000000 + ((i - 1024) << 13);
        }

        for (i in 1...31) {
            exponentTable[i] = i << 23;
        }

        exponentTable[31] = 0x47800000;
        exponentTable[32] = 0x80000000;

        for (i in 33...63) {
            exponentTable[i] = 0x80000000 + ((i - 32) << 23);
        }

        exponentTable[63] = 0xc7800000;

        for (i in 1...64) {
            if (i != 32) {
                offsetTable[i] = 1024;
            }
        }

        return {
            floatView: floatView,
            uint32View: uint32View,
            baseTable: baseTable,
            shiftTable: shiftTable,
            mantissaTable: mantissaTable,
            exponentTable: exponentTable,
            offsetTable: offsetTable
        };
    }

    public static function toHalfFloat(val:Float):Int {
        if (Math.abs(val) > 65504) trace('THREE.DataUtils.toHalfFloat(): Value out of range.');

        val = clamp(val, -65504, 65504);

        _tables.floatView[0] = val;
        var f = _tables.uint32View[0];
        var e = (f >> 23) & 0x1ff;
        return _tables.baseTable[e] + ((f & 0x007fffff) >> _tables.shiftTable[e]);
    }

    public static function fromHalfFloat(val:Int):Float {
        var m = val >> 10;
        _tables.uint32View[0] = _tables.mantissaTable[_tables.offsetTable[m] + (val & 0x3ff)] + _tables.exponentTable[m];
        return _tables.floatView[0];
    }
}