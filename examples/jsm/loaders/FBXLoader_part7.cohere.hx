class BinaryReader {
    var dv:DataView;
    var offset:Int;
    var littleEndian:Bool;
    var _textDecoder:haxe.io.BytesBuffer;

    public function new(buffer:Bytes, littleEndian:Bool = true) {
        this.dv = new DataView(buffer);
        this.offset = 0;
        this.littleEndian = littleEndian;
        this._textDecoder = new haxe.io.BytesBuffer();
    }

    public function getOffset():Int {
        return this.offset;
    }

    public function size():Int {
        return this.dv.byteLength;
    }

    public function skip(length:Int):Void {
        this.offset += length;
    }

    public function getBoolean():Bool {
        return (this.getUint8() & 1) == 1;
    }

    public function getBooleanArray(size:Int):Array<Bool> {
        var a:Array<Bool> = [];
        var i:Int;
        for (i = 0; i < size; i++) {
            a.push(this.getBoolean());
        }
        return a;
    }

    public function getUint8():Int {
        var value:Int = this.dv.getUint8(this.offset);
        this.offset += 1;
        return value;
    }

    public function getInt16():Int {
        var value:Int = this.dv.getInt16(this.offset, this.littleEndian);
        this.offset += 2;
        return value;
    }

    public function getInt32():Int {
        var value:Int = this.dv.getInt32(this.offset, this.littleEndian);
        this.offset += 4;
        return value;
    }

    public function getInt32Array(size:Int):Array<Int> {
        var a:Array<Int> = [];
        var i:Int;
        for (i = 0; i < size; i++) {
            a.push(this.getInt32());
        }
        return a;
    }

    public function getUint32():Int {
        var value:Int = this.dv.getUint32(this.offset, this.littleEndian);
        this.offset += 4;
        return value;
    }

    public function getInt64():Int64 {
        var low:Int, high:Int;
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
            return -Int64.make(high, low);
        } else {
            return Int64.make(high, low);
        }
    }

    public function getInt64Array(size:Int):Array<Int64> {
        var a:Array<Int64> = [];
        var i:Int;
        for (i = 0; i < size; i++) {
            a.push(this.getInt64());
        }
        return a;
    }

    public function getUint64():Int64 {
        var low:Int, high:Int;
        if (this.littleEndian) {
            low = this.getUint32();
            high = this.getUint32();
        } else {
            high = this.getUint32();
            low = this.getUint32();
        }
        return Int64.make(high, low);
    }

    public function getFloat32():Float {
        var value:Float = this.dv.getFloat32(this.offset, this.littleEndian);
        this.offset += 4;
        return value;
    }

    public function getFloat32Array(size:Int):Array<Float> {
        var a:Array<Float> = [];
        var i:Int;
        for (i = 0; i < size; i++) {
            a.push(this.getFloat32());
        }
        return a;
    }

    public function getFloat64():Float {
        var value:Float = this.dv.getFloat64(this.offset, this.littleEndian);
        this.offset += 8;
        return value;
    }

    public function getFloat64Array(size:Int):Array<Float> {
        var a:Array<Float> = [];
        var i:Int;
        for (i = 0; i < size; i++) {
            a.push(this.getFloat64());
        }
        return a;
    }

    public function getArrayBuffer(size:Int):Bytes {
        var value:Bytes = this.dv.buffer.slice(this.offset, this.offset + size);
        this.offset += size;
        return value;
    }

    public function getString(size:Int):String {
        var start:Int = this.offset;
        var a:Bytes = new Bytes(this.dv.buffer, start, size);
        this.skip(size);
        var nullByte:Int = a.indexOf(0);
        if (nullByte >= 0) a = new Bytes(this.dv.buffer, start, nullByte);
        return this._textDecoder.addBytes(a).toString();
    }
}