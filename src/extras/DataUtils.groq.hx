Here is the converted Haxe code:
```
package three.js.src.extras;

import haxe.io.BytesBuffer;
import haxe.io.Float32Array;
import haxe.io.Uint32Array;
import three.math.MathUtils;

class DataUtils {
    static var _tables:Dynamic;

    static function _generateTables():Void {
        // float32 to float16 helpers
        var buffer:BytesBuffer = new BytesBuffer(4);
        var floatView:Float32Array = new Float32Array(cast buffer);
        var uint32View:Uint32Array = new Uint32Array(cast buffer);

        var baseTable:Uint32Array = new Uint32Array(512);
        var shiftTable:Uint32Array = new Uint32Array(512);

        for (i in 0...256) {
            var e:Int = i - 127;

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
        var mantissaTable:Uint32Array = new Uint32Array(2048);
        var exponentTable:Uint32Array = new Uint32Array(64);
        var offsetTable:Uint32Array = new Uint32Array(64);

        for (i in 1...1024) {
            var m:Int = i << 13; // zero pad mantissa bits
            var e:Int = 0; // zero exponent

            // normalized
            while ((m & 0x00800000) === 0) {
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
            if (i !== 32) {
                offsetTable[i] = 1024;
            }
        }

        _tables = {
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
        if (Math.abs(val) > 65504) {
            trace('THREE.DataUtils.toHalfFloat(): Value out of range.');
        }

        val = MathUtils.clamp(val, -65504, 65504);

        _tables.floatView[0] = val;
        var f:Int = _tables.uint32View[0];
        var e:Int = (f >> 23) & 0x1ff;
        return _tables.baseTable[e] + ((f & 0x007fffff) >> _tables.shiftTable[e]);
    }

    public static function fromHalfFloat(val:Int):Float {
        var m:Int = val >> 10;
        _tables.uint32View[0] = _tables.mantissaTable[_tables.offsetTable[m] + (val & 0x3ff)] + _tables.exponentTable[m];
        return _tables.floatView[0];
    }
}
```
Note that I had to make some assumptions about the Haxe equivalents of certain JavaScript features, such as `Uint32Array` and `Float32Array`. I also replaced `console.warn` with `trace`, as Haxe's built-in tracing mechanism.