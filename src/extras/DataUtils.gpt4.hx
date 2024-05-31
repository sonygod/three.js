import MathUtils.clamp;

// Fast Half Float Conversions, http://www.fox-toolkit.org/ftp/fasthalffloatconversion.pdf

class DataUtils {

    private static var _tables = _generateTables();

    private static function _generateTables() {

        // float32 to float16 helpers

        var buffer = haxe.io.Bytes.alloc(4);
        var floatView = haxe.io.Bytes.ofData(buffer.b).getFloat32Array();
        var uint32View = haxe.io.Bytes.ofData(buffer.b).getUInt32Array();

        var baseTable = new haxe.ds.IntMap<Int>();
        var shiftTable = new haxe.ds.IntMap<Int>();

        for (i in 0...256) {

            var e = i - 127;

            // very small number (0, -0)

            if (e < -27) {

                baseTable.set(i, 0x0000);
                baseTable.set(i | 0x100, 0x8000);
                shiftTable.set(i, 24);
                shiftTable.set(i | 0x100, 24);

                // small number (denorm)

            } else if (e < -14) {

                baseTable.set(i, 0x0400 >> (-e - 14));
                baseTable.set(i | 0x100, (0x0400 >> (-e - 14)) | 0x8000);
                shiftTable.set(i, -e - 1);
                shiftTable.set(i | 0x100, -e - 1);

                // normal number

            } else if (e <= 15) {

                baseTable.set(i, (e + 15) << 10);
                baseTable.set(i | 0x100, ((e + 15) << 10) | 0x8000);
                shiftTable.set(i, 13);
                shiftTable.set(i | 0x100, 13);

                // large number (Infinity, -Infinity)

            } else if (e < 128) {

                baseTable.set(i, 0x7c00);
                baseTable.set(i | 0x100, 0xfc00);
                shiftTable.set(i, 24);
                shiftTable.set(i | 0x100, 24);

                // stay (NaN, Infinity, -Infinity)

            } else {

                baseTable.set(i, 0x7c00);
                baseTable.set(i | 0x100, 0xfc00);
                shiftTable.set(i, 13);
                shiftTable.set(i | 0x100, 13);

            }

        }

        // float16 to float32 helpers

        var mantissaTable = new haxe.ds.IntMap<Int>();
        var exponentTable = new haxe.ds.IntMap<Int>();
        var offsetTable = new haxe.ds.IntMap<Int>();

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

            mantissaTable.set(i, m | e);

        }

        for (i in 1024...2048) {

            mantissaTable.set(i, 0x38000000 + ((i - 1024) << 13));

        }

        for (i in 1...31) {

            exponentTable.set(i, i << 23);

        }

        exponentTable.set(31, 0x47800000);
        exponentTable.set(32, 0x80000000);

        for (i in 33...63) {

            exponentTable.set(i, 0x80000000 + ((i - 32) << 23));

        }

        exponentTable.set(63, 0xc7800000);

        for (i in 1...64) {

            if (i != 32) {

                offsetTable.set(i, 1024);

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

    // float32 to float16

    public static function toHalfFloat(val:Float):Int {

        if (Math.abs(val) > 65504) {
            trace('THREE.DataUtils.toHalfFloat(): Value out of range.');
        }

        val = clamp(val, -65504, 65504);

        _tables.floatView.setFloat32(0, val, true);
        var f = _tables.uint32View.getUInt32(0, true);
        var e = (f >> 23) & 0x1ff;
        return _tables.baseTable.get(e) + ((f & 0x007fffff) >> _tables.shiftTable.get(e));

    }

    // float16 to float32

    public static function fromHalfFloat(val:Int):Float {

        var m = val >> 10;
        _tables.uint32View.setUInt32(0, _tables.mantissaTable.get(_tables.offsetTable.get(m) + (val & 0x3ff)) + _tables.exponentTable.get(m), true);
        return _tables.floatView.getFloat32(0, true);

    }

}