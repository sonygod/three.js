class BinaryReader {
    public var dv:haxe.io.Bytes;
    public var offset:Int;
    public var littleEndian:Bool;
    private var _textDecoder:haxe.io.BytesInput;

    public function new(buffer:haxe.io.Bytes, littleEndian:Bool) {
        this.dv = buffer;
        this.offset = 0;
        this.littleEndian = (littleEndian !== null) ? littleEndian : true;
        this._textDecoder = new haxe.io.BytesInput(buffer);
    }

    public function getOffset():Int {
        return this.offset;
    }

    public function size():Int {
        return this.dv.length;
    }

    public function skip(length:Int) {
        this.offset += length;
    }

    public function getBoolean():Bool {
        return (this.getUint8() & 1) == 1;
    }

    public function getBooleanArray(size:Int):Array<Bool> {
        var a:Array<Bool> = [];
        for (i in 0...size) {
            a.push(this.getBoolean());
        }
        return a;
    }

    public function getUint8():Int {
        var value:Int = this.dv.get(this.offset);
        this.offset += 1;
        return value;
    }

    public function getInt16():Int {
        var value:Int = this.dv.getUint16(this.offset, this.littleEndian);
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
        for (i in 0...size) {
            a.push(this.getInt32());
        }
        return a;
    }

    public function getUint32():Int {
        var value:Int = this.dv.getUint32(this.offset, this.littleEndian);
        this.offset += 4;
        return value;
    }

    public function getInt64():Int {
        var low:Int, high:Int;
        if (this.littleEndian) {
            low = this.getUint32();
            high = this.getUint32();
        } else {
            high = this.getUint32();
            low = this.getUint32();
        }
        return (high << 32) | low;
    }

    public function getInt64Array(size:Int):Array<Int> {
        var a:Array<Int> = [];
        for (i in 0...size) {
            a.push(this.getInt64());
        }
        return a;
    }

    public function getUint64():Int {
        var low:Int, high:Int;
        if (this.littleEndian) {
            low = this.getUint32();
            high = this.getUint32();
        } else {
            high = this.getUint32();
            low = this.getUint32();
        }
        return (high << 32) | low;
    }

    public function getFloat32():Float {
        var value:Float = this.dv.getFloat32(this.offset, this.littleEndian);
        this.offset += 4;
        return value;
    }

    public function getFloat32Array(size:Int):Array<Float> {
        var a:Array<Float> = [];
        for (i in 0...size) {
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
        for (i in 0...size) {
            a.push(this.getFloat64());
        }
        return a;
    }

    public function getArrayBuffer(size:Int):haxe.io.Bytes {
        var value:haxe.io.Bytes = this.dv.sub(this.offset, this.offset + size);
        this.offset += size;
        return value;
    }

    public function getString(size:Int):String {
        var start:Int = this.offset;
        var a:haxe.io.Bytes = this.dv.sub(start, start + size);
        this.skip(size);
        var nullByte:Int = a.indexOf(0);
        if (nullByte >= 0) a = a.sub(0, nullByte);
        return this._textDecoder.readString(a);
    }
}