import MathUtils;

// Fast Half Float Conversions, http://www.fox-toolkit.org/ftp/fasthalffloatconversion.pdf

class DataUtils {

	static var _tables:Tables = _generateTables();

	static function toHalfFloat(val:Float):Int {
		if (Math.abs(val) > 65504) {
			Sys.warning('THREE.DataUtils.toHalfFloat(): Value out of range.');
		}
		val = MathUtils.clamp(val, -65504, 65504);
		var f = val.toInt32();
		var e = (f >> 23) & 0x1ff;
		return _tables.baseTable[e] + ((f & 0x007fffff) >> _tables.shiftTable[e]);
	}

	static function fromHalfFloat(val:Int):Float {
		var m = val >> 10;
		var f = _tables.mantissaTable[_tables.offsetTable[m] + (val & 0x3ff)] + _tables.exponentTable[m];
		return f.toFloat();
	}

	static function _generateTables():Tables {

		// float32 to float16 helpers

		var baseTable:Array<Int> = new Array<Int>(512);
		var shiftTable:Array<Int> = new Array<Int>(512);

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

		var mantissaTable:Array<Int> = new Array<Int>(2048);
		var exponentTable:Array<Int> = new Array<Int>(64);
		var offsetTable:Array<Int> = new Array<Int>(64);

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
			baseTable:baseTable,
			shiftTable:shiftTable,
			mantissaTable:mantissaTable,
			exponentTable:exponentTable,
			offsetTable:offsetTable
		};

	}

}

typedef Tables = {
	baseTable:Array<Int>,
	shiftTable:Array<Int>,
	mantissaTable:Array<Int>,
	exponentTable:Array<Int>,
	offsetTable:Array<Int>
};

class MathUtils {

	static function clamp(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

}