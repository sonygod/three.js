import haxe.io.Bytes;
import haxe.io.BytesInput;

class DataViewReader {
    private var dv:BytesInput;
    private var offset:Int;
    private var textDecoder:haxe.io.Encoding.UTF8;

    public function new(buffer:Bytes) {
        dv = new BytesInput(buffer);
        offset = 0;
        textDecoder = haxe.io.Encoding.UTF8;
    }

    public function size():Int {
        return dv.getBytes().length;
    }

    public function setOffset(offset:Int) {
        if (offset > 0 && offset < dv.getBytes().length) {
            this.offset = offset;
        } else {
            trace("LWOLoader: invalid buffer offset");
        }
    }

    public function endOfFile():Bool {
        return offset >= size();
    }

    public function skip(length:Int) {
        offset += length;
    }

    public function getUint8():Int {
        var value = dv.readInt8(offset);
        offset += 1;
        return value;
    }

    public function getUint16():Int {
        var value = dv.readInt16(offset);
        offset += 2;
        return value;
    }

    public function getInt32():Int {
        var value = dv.readInt32(offset);
        offset += 4;
        return value;
    }

    public function getUint32():Int {
        var value = dv.readInt32(offset);
        offset += 4;
        return value;
    }

    public function getUint64():Int {
        var high = getUint32();
        var low = getUint32();
        return high * 0x100000000 + low;
    }

    public function getFloat32():Float {
        var value = dv.readFloat(offset);
        offset += 4;
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
        var value = dv.readDouble(offset);
        offset += 8;
        return value;
    }

    public function getFloat64Array(size:Int):Array<Float> {
        var a:Array<Float> = [];
        for (i in 0...size) {
            a.push(getFloat64());
        }
        return a;
    }

    public function getVariableLengthIndex():Int {
        var firstByte = getUint8();
        if (firstByte == 255) {
            return getUint8() * 65536 + getUint8() * 256 + getUint8();
        }
        return firstByte * 256 + getUint8();
    }

    public function getIDTag():String {
        return getString(4);
    }

    public function getString(size:Int = 0):String {
        if (size == 0) return null;
        var start = offset;
        var length:Int;
        var result:String;
        if (size > 0) {
            length = size;
            result = textDecoder.decodeBytes(dv.getBytes(), start, size);
        } else {
            length = dv.getBytes().indexOf(0, start) - start;
            result = textDecoder.decodeBytes(dv.getBytes(), start, length);
            length++; // account for null byte in length
            length += length % 2; // if string with terminating nullbyte is uneven, extra nullbyte is added, skip that too
        }
        skip(length);
        return result;
    }

    public function getStringArray(size:Int):Array<String> {
        var a:Array<String> = getString(size).split("\0");
        return a.filter(function(s:String) return s != "");
    }
}