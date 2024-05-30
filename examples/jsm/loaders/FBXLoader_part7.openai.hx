import haxe.io.BytesData;
import haxe.io.BytesInput;

class BinaryReader {
  var dv:BytesData;
  var offset:Int;
  var littleEndian:Bool;
  var _textDecoder:TextDecoder;

  public function new(buffer:BytesData, littleEndian:Bool = true) {
    this.dv = buffer;
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

  public function skip(length:Int):Void {
    this.offset += length;
  }

  // seems like true/false representation depends on exporter.
  // true: 1 or 'Y'(=0x59), false: 0 or 'T'(=0x54)
  // then sees LSB.
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

  // JavaScript doesn't support 64-bit integer so calculate this here
  // 1 << 32 will return 1 so using multiply operation instead here.
  // There's a possibility that this method returns wrong value if the value
  // is out of the range between Number.MAX_SAFE_INTEGER and Number.MIN_SAFE_INTEGER.
  // TODO: safely handle 64-bit integer
  public function getInt64():Int64 {
    var low:Int;
    var high:Int;

    if (this.littleEndian) {
      low = this.getUint32();
      high = this.getUint32();
    } else {
      high = this.getUint32();
      low = this.getUint32();
    }

    // calculate negative value
    if (high & 0x80000000 != 0) {
      high = ~high & 0xFFFFFFFF;
      low = ~low & 0xFFFFFFFF;

      if (low == 0xFFFFFFFF) high = (high + 1) & 0xFFFFFFFF;

      low = (low + 1) & 0xFFFFFFFF;

      return -(high * 0x100000000 + low);
    }

    return high * 0x100000000 + low;
  }

  public function getInt64Array(size:Int):Array<Int64> {
    var a:Array<Int64> = [];
    for (i in 0...size) {
      a.push(this.getInt64());
    }
    return a;
  }

  // Note: see getInt64() comment
  public function getUint64():Int64 {
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

  public function getArrayBuffer(size:Int):BytesData {
    var value:BytesData = this.dv.bytes.Slice(this.offset, this.offset + size);
    this.offset += size;
    return value;
  }

  public function getString(size:Int):String {
    var start:Int = this.offset;
    var a:BytesData = this.dv.bytes.Slice(start, start + size);
    this.skip(size);

    var nullByte:Int = a.indexOf(0);
    if (nullByte >= 0) a = a.Slice(0, nullByte);

    return this._textDecoder.decode(a);
  }
}