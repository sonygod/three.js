import Math;

class DataUtils {
    private static var _tables:Dynamic = _generateTables();

    private static function _generateTables():Dynamic {
        var buffer:Uint8Array = new Uint8Array(4);
        var floatView:Float32Array = new Float32Array(buffer.buffer);
        var uint32View:Uint32Array = new Uint32Array(buffer.buffer);

        var baseTable:Uint32Array = new Uint32Array(512);
        var shiftTable:Uint32Array = new Uint32Array(512);

        for (var i:Int = 0; i < 256; ++i) {
            var e:Int = i - 127;

            if (e < -27) {
                baseTable[i] = 0x0000;
                baseTable[i | 0x100] = 0x8000;
                shiftTable[i] = 24;
                shiftTable[i | 0x100] = 24;
            } else if (e < -14) {
                baseTable[i] = 0x0400 >> (-e - 14);
                baseTable[i | 0x100] = (0x0400 >> (-e - 14)) | 0x8000;
                shiftTable[i] = -e - 1;
                shiftTable[i | 0x100] = -e - 1;
            } else if (e <= 15) {
                baseTable[i] = (e + 15) << 10;
                baseTable[i | 0x100] = ((e + 15) << 10) | 0x8000;
                shiftTable[i] = 13;
                shiftTable[i | 0x100] = 13;
            } else if (e < 128) {
                baseTable[i] = 0x7c00;
                baseTable[i | 0x100] = 0xfc00;
                shiftTable[i] = 24;
                shiftTable[i | 0x100] = 24;
            } else {
                baseTable[i] = 0x7c00;
                baseTable[i | 0x100] = 0xfc00;
                shiftTable[i] = 13;
                shiftTable[i | 0x100] = 13;
            }
        }

        var mantissaTable:Uint32Array = new Uint32Array(2048);
        var exponentTable:Uint32Array = new Uint32Array(64);
        var offsetTable:Uint32Array = new Uint32Array(64);

        for (var i:Int = 1; i < 1024; ++i) {
            var m:Int = i << 13;
            var e:Int = 0;

            while ((m & 0x00800000) == 0) {
                m <<= 1;
                e -= 0x00800000;
            }

            m &= ~0x00800000;
            e += 0x38800000;

            mantissaTable[i] = m | e;
        }

        for (var i:Int = 1024; i < 2048; ++i) {
            mantissaTable[i] = 0x38000000 + ((i - 1024) << 13);
        }

        for (var i:Int = 1; i < 31; ++i) {
            exponentTable[i] = i << 23;
        }

        exponentTable[31] = 0x47800000;
        exponentTable[32] = 0x80000000;

        for (var i:Int = 33; i < 63; ++i) {
            exponentTable[i] = 0x80000000 + ((i - 32) << 23);
        }

        exponentTable[63] = 0xc7800000;

        for (var i:Int = 1; i < 64; ++i) {
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
        if (Math.abs(val) > 65504) trace('Value out of range.');

        val = Math.min(Math.max(val, -65504), 65504);

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