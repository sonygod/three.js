import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Input;

class Assert {
  public static function strictEqual(actual:Dynamic, expected:Dynamic, ...args:Array<Dynamic>):Void {
    args = args.length == 0 ? [] : args;
    if (actual != expected) {
      throw new Error("$actual (actual) should equal $expected (expected): ${args.join(' ')}");
    }
  }

  public static function notStrictEqual(actual:Dynamic, expected:Dynamic, ...args:Array<Dynamic>):Void {
    args = args.length == 0 ? [] : args;
    if (actual == expected) {
      throw new Error("$actual (actual) should NOT equal $expected (expected): ${args.join(' ')}");
    }
  }
}

class OGCParser {
  public static function parse(buf:Bytes):Dynamic {
    Assert.strictEqual(buf.get(0), 0x47, 'bad header');
    Assert.strictEqual(buf.get(1), 0x50, 'bad header');
    Assert.strictEqual(buf.get(2), 0, 'unknown version'); // version
    var flags = buf.get(3);

    var flag_x = (flags >> 5) & 1;
    // var flag_empty_geo = (flags >> 4) & 1;  // 1 = empty, 0 non-empty
    var flag_byteOrder = (flags >> 0) & 1; // 1 = little endian, 0 = big
    var flag_envelope = (flags >> 1) & 7;

    Assert.strictEqual(flag_x, 0, 'x must be 0');

    var envelopeSizes = [
      0, // 0: non
      4, // 1: minx, maxx, miny, maxy
      6, // 2: minx, maxx, miny, maxy, minz, maxz
      6, // 3: minx, maxx, miny, maxy, minm, maxm
      8, // 4: minx, maxx, miny, maxy, minz, maxz, minm, maxm
    ];

    var envelopeSize = envelopeSizes[flag_envelope];
    Assert.notStrictEqual(envelopeSize, null);

    var headerSize = 8;
    var cursor = headerSize;

    var dataView = new BytesInput(buf);
    /*
    var readBE = {
      getDouble() { var v = buf.readDoubleBE(cursor); cursor += 8 ; return v; },
      getFloat()  { var v = buf.readFloatBE(cursor);  cursor += 4 ; return v; },
      getInt8()   { var v = buf.readInt8(cursor);     cursor += 1 ; return v; },
      getUint8()  { var v = buf.readUInt8(cursor);    cursor += 1 ; return v; },
      getInt16()  { var v = buf.readInt16BE(cursor);  cursor += 2 ; return v; },
      getUint16() { var v = buf.readUInt16BE(cursor); cursor += 2 ; return v; },
      getInt32()  { var v = buf.readInt32BE(cursor);  cursor += 4 ; return v; },
      getUint32() { var v = buf.readUInt32BE(cursor); cursor += 4 ; return v; },
    };

    var readLE = {
      getDouble() { var v = buf.readDoubleLE(cursor); cursor += 8 ; return v; },
      getFloat()  { var v = buf.readFloatLE(cursor);  cursor += 4 ; return v; },
      getInt8()   { var v = buf.readInt8(cursor);     cursor += 1 ; return v; },
      getUint8()  { var v = buf.readUInt8(cursor);    cursor += 1 ; return v; },
      getInt16()  { var v = buf.readInt16LE(cursor);  cursor += 2 ; return v; },
      getUint16() { var v = buf.readUInt16LE(cursor); cursor += 2 ; return v; },
      getInt32()  { var v = buf.readInt32LE(cursor);  cursor += 4 ; return v; },
      getUint32() { var v = buf.readUInt32LE(cursor); cursor += 4 ; return v; },
    };
    */

    var littleEndian = false;
    var endianStack = [];

    function pushByteOrder(byteOrder:Bool) {
      endianStack.push(littleEndian);
      littleEndian = byteOrder;
    }

    function popByteOrder() {
      littleEndian = endianStack.pop();
    }

    var getDouble = function():Float {
      var v = dataView.readDouble(littleEndian); cursor += 8; return v;
    };

    // var getFloat =  () => { var v = dataView.getFloat32(cursor, littleEndian); cursor += 4 ; return v; };
    var getInt8 = function():Int {
      var v = dataView.readInt8(); cursor += 1; return v;
    };

    // var getUint8 =  () => { var v = dataView.getUint8(cursor, littleEndian);   cursor += 1 ; return v; };
    // var getInt16 =  () => { var v = dataView.getInt16(cursor, littleEndian);   cursor += 2 ; return v; };
    // var getUint16 = () => { var v = dataView.getUint16(cursor, littleEndian);  cursor += 2 ; return v; };
    // var getInt32 =  () => { var v = dataView.getInt32(cursor, littleEndian);   cursor += 4 ; return v; };
    var getUint32 = function():Int {
      var v = dataView.readUInt32(littleEndian); cursor += 4; return v;
    };

    pushByteOrder(flag_byteOrder == 1);

    var envelope = [];
    for (var i = 0; i < envelopeSize; ++i) {
      envelope.push(getDouble());
    }

    var primitives = [];

    function getPoints(num:Int):Array<Float> {
      var points = [];
      for (var i = 0; i < num; ++i) {
        points.push(getDouble(), getDouble());
      }
      return points;
    }

    function getRings(num:Int):Array<Array<Float>> {
      var rings = [];
      for (var i = 0; i < num; ++i) {
        rings.push(getPoints(getUint32()));
      }
      return rings;
    }

    function pointHandler():Dynamic {
      return {
        type: 'point',
        point: getPoints(1),
      };
    }

    function lineStringHandler():Dynamic {
      return {
        type: 'lineString',
        points: getPoints(getUint32()),
      };
    }

    function polygonHandler():Dynamic {
      return {
        type: 'polygon',
        rings: getRings(getUint32()),
      };
    }

    function multiPointHandler():Dynamic {
      // WTF?
      var points = [];
      var num = getUint32();
      for (var i = 0; i < num; ++i) {
        pushByteOrder(getInt8() == 1);
        var type = getUint32();
        Assert.strictEqual(type, 1); // must be point
        points.push(getDouble(), getDouble());
        popByteOrder();
      }
      return {
        type: 'multiPoint',
        points,
      };
    }

    function multiLineStringHandler():Dynamic {
      // WTF?
      var lineStrings = [];
      var num = getUint32();
      for (var i = 0; i < num; ++i) {
        pushByteOrder(getInt8() == 1);
        var type = getUint32();
        Assert.strictEqual(type, 2); // must be lineString
        lineStrings.push(getPoints(getUint32()));
        popByteOrder();
      }
      return {
        type: 'multiLineString',
        lineStrings,
      };
    }

    function multiPolygonHandler():Dynamic {
      // WTF?
      var polygons = [];
      var num = getUint32();
      for (var i = 0; i < num; ++i) {
        pushByteOrder(getInt8() == 1);
        var type = getUint32();
        Assert.strictEqual(type, 3); // must be polygon
        polygons.push(getRings(getUint32()));
        popByteOrder();
      }
      return {
        type: 'multiPolygon',
        polygons,
      };
    }

    var typeHandlers = [
      null, // 0
      pointHandler, // 1
      lineStringHandler, // 2
      polygonHandler, // 3
      multiPointHandler, // 4
      multiLineStringHandler, // 5,
      multiPolygonHandler, // 6,
    ];

    var end = buf.length;
    while (cursor < end) {
      pushByteOrder(getInt8() == 1);
      var type = getUint32();
      var handler = typeHandlers[type];
      Assert.notStrictEqual(handler, null, 'unknown type');
      primitives.push(handler());
      popByteOrder();
    }

    return {
      envelope,
      primitives,
    };
  }
}