class BinaryReader {

	var dv:haxe.io.BytesData;
	var offset:Int;
	var littleEndian:Bool;
	var _textDecoder:haxe.io.BytesInput;

	public function new(buffer:haxe.io.Bytes, littleEndian:Bool) {
		this.dv = haxe.io.BytesData.ofData(buffer);
		this.offset = 0;
		this.littleEndian = if (littleEndian !== undefined) littleEndian else true;
		this._textDecoder = new haxe.io.BytesInput();
	}

	public function getOffset():Int {
		return this.offset;
	}

	public function size():Int {
		return this.dv.length;
	}

	public function skip(length:Int):Void {
		this.offset += length;
	}

	public function getBoolean():Bool {
		return (this.getUint8() & 1) === 1;
	}

	public function getBooleanArray(size:Int):Array<Bool> {
		var a = [];
		for (i in 0...size) {
			a.push(this.getBoolean());
		}
		return a;
	}

	public function getUint8():Int {
		var value = this.dv.getUInt8(this.offset);
		this.offset += 1;
		return value;
	}

	public function getInt16():Int {
		var value = this.dv.getInt16(this.offset, this.littleEndian);
		this.offset += 2;
		return value;
	}

	public function getInt32():Int {
		var value = this.dv.getInt32(this.offset, this.littleEndian);
		this.offset += 4;
		return value;
	}

	public function getInt32Array(size:Int):Array<Int> {
		var a = [];
		for (i in 0...size) {
			a.push(this.getInt32());
		}
		return a;
	}

	public function getUint32():Int {
		var value = this.dv.getUInt32(this.offset, this.littleEndian);
		this.offset += 4;
		return value;
	}

	public function getInt64():Int {
		var low:Int;
		var high:Int;
		if (this.littleEndian) {
			low = this.getUint32();
			high = this.getUint32();
		} else {
			high = this.getUint32();
			low = this.getUint32();
		}
		if (high & 0x80000000) {
			high = ~high & 0xFFFFFFFF;
			low = ~low & 0xFFFFFFFF;
			if (low == 0xFFFFFFFF) high = (high + 1) & 0xFFFFFFFF;
			low = (low + 1) & 0xFFFFFFFF;
			return -(high * 0x100000000 + low);
		}
		return high * 0x100000000 + low;
	}

	public function getInt64Array(size:Int):Array<Int> {
		var a = [];
		for (i in 0...size) {
			a.push(this.getInt64());
		}
		return a;
	}

	public function getUint64():Int {
		var low:Int;
		var high:Int;
		if (this.littleEndian) {
			low = this.getUint32();
			high = this.getUint32();
		} else {
			high = this.getUint32();
			low = this.getUint32();
		}
		return high * 0x100000000 + low;
	}

	public function getFloat32():Float {
		var value = this.dv.getFloat32(this.offset, this.littleEndian);
		this.offset += 4;
		return value;
	}

	public function getFloat32Array(size:Int):Array<Float> {
		var a = [];
		for (i in 0...size) {
			a.push(this.getFloat32());
		}
		return a;
	}

	public function getFloat64():Float {
		var value = this.dv.getFloat64(this.offset, this.littleEndian);
		this.offset += 8;
		return value;
	}

	public function getFloat64Array(size:Int):Array<Float> {
		var a = [];
		for (i in 0...size) {
			a.push(this.getFloat64());
		}
		return a;
	}

	public function getArrayBuffer(size:Int):haxe.io.Bytes {
		var value = this.dv.slice(this.offset, this.offset + size);
		this.offset += size;
		return value;
	}

	public function getString(size:Int):String {
		var start = this.offset;
		var a = this.dv.sub(start, start + size);
		this.skip(size);
		var nullByte = a.indexOf(0);
		if (nullByte >= 0) a = a.sub(0, nullByte);
		return haxe.io.Bytes.ofData(a).toString();
	}
}