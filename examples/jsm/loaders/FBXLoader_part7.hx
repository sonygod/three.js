package three.js.examples.jsm.loaders;

import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.UInt8Array;

class BinaryReader {

    private var dv:BytesData;
    private var offset:Int;
    private var littleEndian:Bool;
    private var _textDecoder:TextDecoder;

    public function new(buffer:Bytes, littleEndian:Bool = true) {
        this.dv = buffer.getData();
        this.offset = 0;
        this.littleEndian = littleEndian;
        this._textDecoder = new TextDecoder();
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
        return (getUint8() & 1) == 1;
    }

    public function getBooleanArray(size:Int):Array<Bool> {
        var a:Array<Bool> = [];
        for (i in 0...size) {
            a.push(getBoolean());
        }
        return a;
    }

    public function getUint8():Int {
        var value:Int = this.dv.getUInt8(this.offset);
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
        for (i in 0...size) {
            a.push(getInt32());
        }
        return a;
    }

    public function getUint32():Int {
        var value:Int = this.dv.getUInt32(this.offset, this.littleEndian);
        this.offset += 4;
        return value;
    }

    public function getInt64():Int {
        var low:Int;
        var high:Int;

        if (this.littleEndian) {
            low = getUint32();
            high = getUint32();
        } else {
            high = getUint32();
            low = getUint32();
        }

        if (high & 0x80000000 != 0) {
            high = ~high & 0xFFFFFFFF;
            low = ~low & 0xFFFFFFFF;

            if (low == 0xFFFFFFFF) high = (high + 1) & 0xFFFFFFFF;

            low = (low + 1) & 0xFFFFFFFF;

            return - (high * 0x100000000 + low);
        }

        return high * 0x100000000 + low;
    }

    public function getInt64Array(size:Int):Array<Int> {
        var a:Array<Int> = [];
        for (i in 0...size) {
            a.push(getInt64());
        }
        return a;
    }

    public function getUint64():Int {
        var low:Int;
        var high:Int;

        if (this.littleEndian) {
            low = getUint32();
            high = getUint32();
        } else {
            high = getUint32();
            low = getUint32();
        }

        return high * 0x100000000 + low;
    }

    public function getFloat32():Float {
        var value:Float = this.dv.getFloat32(this.offset, this.littleEndian);
        this.offset += 4;
        return value;
    }

    public function getFloat32Array(size:Int):Array<Float> {
        var a:Array<Float> = [];
        for (i in 0...size) {
            a.push(getFloat32());
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
            a.push(getFloat64());
        }
        return a;
    }

    public function getArrayBuffer(size:Int):Bytes {
        var value:Bytes = this.dv.sub(this.offset, this.offset + size);
        this.offset += size;
        return value;
    }

    public function getString(size:Int):String {
        var start:Int = this.offset;
        var a:UInt8Array = new UInt8Array(this.dv, start, size);

        skip(size);

        var nullByte:Int = a.indexOf(0);
        if (nullByte >= 0) a = new UInt8Array(this.dv, start, nullByte);

        return this._textDecoder.decode(a);
    }
}