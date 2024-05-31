import js.lib.DataView;
import js.lib.Uint8Array;
import js.lib.TextDecoder;

class BinaryReader {

    public var dv:DataView;
    public var offset(default, set_offset):Int;
    public var littleEndian:Bool;
    var _textDecoder:TextDecoder;

    function set_offset(v:Int):Int {
        this.offset = v;
        return v;
    }

    public function new(buffer: js.lib.ArrayBuffer, littleEndian:Bool = true) {
        this.dv = new DataView(buffer);
        this.offset = 0;
        this.littleEndian = littleEndian;
        this._textDecoder = new TextDecoder();
    }

    public function getOffset():Int {
        return this.offset;
    }

    public function size():Int {
        return this.dv.buffer.byteLength;
    }

    public function skip(length:Int):Void {
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

    public function getUint8():UInt {
        var value = this.dv.getUint8(this.offset);
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

    public function getUint32():UInt {
        var value = this.dv.getUint32(this.offset, this.littleEndian);
        this.offset += 4;
        return value;
    }

    public function getInt64():Int {
        var low:UInt;
        var high:UInt;

        if (this.littleEndian) {
            low = this.getUint32();
            high = this.getUint32();
        } else {
            high = this.getUint32();
            low = this.getUint32();
        }

        if (high & 0x80000000 != 0) {
            high = (~high) & 0xFFFFFFFF;
            low = (~low) & 0xFFFFFFFF;

            if (low == 0xFFFFFFFF) {
                high = (high + 1) & 0xFFFFFFFF;
            }

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

    public function getUint64():UInt {
        var low:UInt;
        var high:UInt;

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
        var a:Array<Float> = [];
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
        var a:Array<Float> = [];
        for (i in 0...size) {
            a.push(this.getFloat64());
        }
        return a;
    }

    public function getArrayBuffer(size:Int):js.lib.ArrayBuffer {
        var value = this.dv.buffer.slice(this.offset, this.offset + size);
        this.offset += size;
        return value;
    }

    public function getString(size:Int):String {
        var start = this.offset;
        var a = new Uint8Array(this.dv.buffer, start, size);

        this.skip(size);

        var nullByte = a.indexOf(0);
        if (nullByte >= 0) a = new Uint8Array(this.dv.buffer, start, nullByte);

        return this._textDecoder.decode(a);
    }
}