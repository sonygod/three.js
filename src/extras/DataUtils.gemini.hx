import haxe.io.Bytes;
import haxe.io.Input;
import haxe.io.Output;
import haxe.io.BytesInput;

class DataUtils {

	static function toHalfFloat(val:Float):Int {
		if (Math.abs(val) > 65504) trace("THREE.DataUtils.toHalfFloat(): Value out of range.");
		val = clamp(val, -65504, 65504);
		var f = floatToUint32(val);
		var e = (f >> 23) & 0x1ff;
		return _tables.baseTable[e] + ((f & 0x007fffff) >> _tables.shiftTable[e]);
	}

	static function fromHalfFloat(val:Int):Float {
		var m = val >> 10;
		return uint32ToFloat(_tables.mantissaTable[_tables.offsetTable[m] + (val & 0x3ff)] + _tables.exponentTable[m]);
	}

	static function floatToUint32(f:Float):Int {
		var b = new Bytes(4);
		var out = new Output(b);
		out.writeFloat(f);
		return b.get(0) | b.get(1) << 8 | b.get(2) << 16 | b.get(3) << 24;
	}

	static function uint32ToFloat(i:Int):Float {
		var b = new Bytes(4);
		b.set(0, i & 0xff);
		b.set(1, (i >> 8) & 0xff);
		b.set(2, (i >> 16) & 0xff);
		b.set(3, (i >> 24) & 0xff);
		var in_ = new BytesInput(b);
		return in_.readFloat();
	}

	static function clamp(x:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, x));
	}

	static var _tables:Tables = _generateTables();

	static function _generateTables():Tables {
		var baseTable = new Array<Int>(512);
		var shiftTable = new Array<Int>(512);
		for (i in 0...256) {
			var e = i - 127;
			if (e < -27) {
				baseTable[i] = 0x0000;
				baseTable[i | 0x100] = 0x8000;
				shiftTable[i] = 24;
				shiftTable[i | 0x100] = 24;
			} else if (e < -14) {
				baseTable[i] = 0x0400 >> (- e - 14);
				baseTable[i | 0x100] = (0x0400 >> (- e - 14)) | 0x8000;
				shiftTable[i] = - e - 1;
				shiftTable[i | 0x100] = - e - 1;
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

		var mantissaTable = new Array<Int>(2048);
		var exponentTable = new Array<Int>(64);
		var offsetTable = new Array<Int>(64);
		for (i in 1...1024) {
			var m = i << 13;
			var e = 0;
			while ((m & 0x00800000) == 0) {
				m <<= 1;
				e -= 0x00800000;
			}
			m &= ~0x00800000;
			e += 0x38800000;
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
		return { baseTable: baseTable, shiftTable: shiftTable, mantissaTable: mantissaTable, exponentTable: exponentTable, offsetTable: offsetTable };
	}
}

typedef Tables = {
	baseTable:Array<Int>,
	shiftTable:Array<Int>,
	mantissaTable:Array<Int>,
	exponentTable:Array<Int>,
	offsetTable:Array<Int>
};