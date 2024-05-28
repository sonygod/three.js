import haxe.io.Bytes;

class DataUtils {
    public static inline function toHalfFloat(val:Float):Int {
        if (Math.abs(val) > 65504.0) {
            trace("DataUtils: Value out of range.");
        }

        val = Math.clamp(val, -65504.0, 65504.0);

        var f:Int = Std.int(val);
        var e:Int = (f >> 23) & 0x1ff;
        return _tables.baseTable[e] + ((f & 0x007fffff) >> _tables.shiftTable[e]);
    }

    public static inline function fromHalfFloat(val:Int):Float {
        var m:Int = val >> 10;
        var f:Int = _tables.mantissaTable[_tables.offsetTable[m] + (val & 0x3ff)] + _tables.exponentTable[m];
        return f / (1 << 23);
    }
}

class _tables {
    static var baseTable:Array<Int> = new Array<Int>();
    static var shiftTable:Array<Int> = new Array<Int>();
    static var mantissaTable:Array<Int> = new Array<Int>();
    static var exponentTable:Array<Int> = new Array<Int>();
    static var offsetTable:Array<Int> = new Array<Int>();

    public static function new() {
        var buffer:Bytes = new Bytes(4);
        var floatView:Float32Array = new Float32Array(buffer.getData());
        var uint32View:Uint32Array = new Uint32Array(buffer.getData());

        for (i in 0...256) {
            var e:Int = i - 127;

            if (e < -27) {
                baseTable.push(0x0000);
                baseTable.push(0x8000);
                shiftTable.push(24);
                shiftTable.push(24);
            } else if (e < -14) {
                baseTable.push(0x0400 >> (-e - 14));
                baseTable.push((0x0400 >> (-e - 14)) | 0x8000);
                shiftTable.push(-e - 1);
                shiftTable.push(-e - 1);
            } else if (e <= 15) {
                baseTable.push((e + 15) << 10);
                baseTable.push(((e + 15) << 10) | 0x8000);
                shiftTable.push(13);
                shiftTable.push(13);
            } else if (e < 128) {
                baseTable.push(0x7c00);
                baseTable.push(0xfc00);
                shiftTable.push(24);
                shiftTable.push(24);
            } else {
                baseTable.push(0x7c00);
                baseTable.push(0xfc00);
                shiftTable.push(13);
                shiftTable.push(13);
            }
        }

        for (i in 1...1024) {
            var m:Int = i << 13;
            var e:Int = 0;

            while ((m & 0x00800000) == 0) {
                m = m << 1;
                e = e - 0x00800000;
            }

            m = m & ~0x00800000;
            e = e + 0x38800000;
            mantissaTable.push(m | e);
        }

        for (i in 1024...2048) {
            mantissaTable.push(0x38000000 + ((i - 1024) << 13));
        }

        for (i in 1...31) {
            exponentTable.push(i << 23);
        }

        exponentTable.push(0x47800000);
        exponentTable.push(0x80000000);

        for (i in 33...63) {
            exponentTable.push(0x80000000 + ((i - 32) << 23));
        }

        exponentTable.push(0xc7800000);

        for (i in 1...64) {
            if (i != 32) {
                offsetTable.push(1024);
            }
        }
    }
}

var _tables_instance = new _tables();