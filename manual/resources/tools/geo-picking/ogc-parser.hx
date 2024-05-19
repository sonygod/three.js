package three.js.manual.resources.tools.geo_picking;

import haxe.io.BytesData;
import haxe.io.Bytes;

class OGCParser {
    static function assertStrictEqual(actual:Dynamic, expected:Dynamic, ?args:Array<Dynamic>):Void {
        if (actual != expected) {
            throw new Error('${actual} (actual) should equal ${expected} (expected): ${args.join(" ")}');
        }
    }

    static function assertNotStrictEqual(actual:Dynamic, expected:Dynamic, ?args:Array<Dynamic>):Void {
        if (actual == expected) {
            throw new Error('${actual} (actual) should NOT equal ${expected} (expected): ${args.join(" ")}');
        }
    }

    static function parse(buf:BytesData):{envelope:Array<Float>, primitives:Array<Dynamic>} {
        assertStrictEqual(buf.get(0), 0x47, 'bad header');
        assertStrictEqual(buf.get(1), 0x50, 'bad header');
        assertStrictEqual(buf.get(2), 0, 'unknown version'); // version
        var flags:Int = buf.get(3);
        var flag_x:Int = (flags >> 5) & 1;
        // var flag_empty_geo:Int = (flags >> 4) & 1;  // 1 = empty, 0 non-empty
        var flag_byteOrder:Int = (flags >> 0) & 1; // 1 = little endian, 0 = big
        var flag_envelope:Int = (flags >> 1) & 7;

        assertStrictEqual(flag_x, 0, 'x must be 0');

        var envelopeSizes:Array<Int> = [
            0, // 0: non
            4, // 1: minx, maxx, miny, maxy
            6, // 2: minx, maxx, miny, maxy, minz, maxz
            6, // 3: minx, maxx, miny, maxy, minm, maxm
            8, // 4: minx, maxx, miny, maxy, minz, maxz, minm, maxm
        ];

        var envelopeSize:Int = envelopeSizes[flag_envelope];
        assertNotStrictEqual(envelopeSize, null);

        var headerSize:Int = 8;
        var cursor:Int = headerSize;

        var dataView:BytesInput = new BytesInput(buf);

        var littleEndian:Bool = flag_byteOrder == 1;
        var endianStack:Array<Bool> = [];

        function pushByteOrder(byteOrder:Bool):Void {
            endianStack.push(littleEndian);
            littleEndian = byteOrder;
        }

        function popByteOrder():Void {
            littleEndian = endianStack.pop();
        }

        function getDouble():Float {
            var v:Float = littleEndian ? dataView.readFloatLE(cursor) : dataView.readFloatBE(cursor);
            cursor += 8;
            return v;
        }

        function getInt8():Int {
            var v:Int = dataView.readInt8(cursor);
            cursor += 1;
            return v;
        }

        function getUint32():Int {
            var v:Int = littleEndian ? dataView.readUInt32LE(cursor) : dataView.readUInt32BE(cursor);
            cursor += 4;
            return v;
        }

        pushByteOrder(flag_byteOrder);

        var envelope:Array<Float> = [];
        for (i in 0...envelopeSize) {
            envelope.push(getDouble());
        }

        var primitives:Array<Dynamic> = [];

        function getPoints(num:Int):Array<Float> {
            var points:Array<Float> = [];
            for (i in 0...num) {
                points.push(getDouble(), getDouble());
            }
            return points;
        }

        function getRings(num:Int):Array<Array<Float>> {
            var rings:Array<Array<Float>> = [];
            for (i in 0...num) {
                rings.push(getPoints(getUint32()));
            }
            return rings;
        }

        function pointHandler():{type:String, point:Array<Float>} {
            return {
                type: 'point',
                point: getPoints(1),
            };
        }

        function lineStringHandler():{type:String, points:Array<Float>} {
            return {
                type: 'lineString',
                points: getPoints(getUint32()),
            };
        }

        function polygonHandler():{type:String, rings:Array<Array<Float>>} {
            return {
                type: 'polygon',
                rings: getRings(getUint32()),
            };
        }

        function multiPointHandler():{type:String, points:Array<Float>} {
            var points:Array<Float> = [];
            var num:Int = getUint32();
            for (i in 0...num) {
                pushByteOrder(getInt8());
                var type:Int = getUint32();
                assertStrictEqual(type, 1); // must be point
                points.push(getDouble(), getDouble());
                popByteOrder();
            }
            return {
                type: 'multiPoint',
                points: points,
            };
        }

        function multiLineStringHandler():{type:String, lineStrings:Array<Array<Float>>} {
            var lineStrings:Array<Array<Float>> = [];
            var num:Int = getUint32();
            for (i in 0...num) {
                pushByteOrder(getInt8());
                var type:Int = getUint32();
                assertStrictEqual(type, 2); // must be lineString
                lineStrings.push(getPoints(getUint32()));
                popByteOrder();
            }
            return {
                type: 'multiLineString',
                lineStrings: lineStrings,
            };
        }

        function multiPolygonHandler():{type:String, polygons:Array<Array<Array<Float>>>} {
            var polygons:Array<Array<Array<Float>>> = [];
            var num:Int = getUint32();
            for (i in 0...num) {
                pushByteOrder(getInt8());
                var type:Int = getUint32();
                assertStrictEqual(type, 3); // must be polygon
                polygons.push(getRings(getUint32()));
                popByteOrder();
            }
            return {
                type: 'multiPolygon',
                polygons: polygons,
            };
        }

        var typeHandlers:Array<Dynamic->Dynamic> = [
            null, // 0
            pointHandler, // 1
            lineStringHandler, // 2
            polygonHandler, // 3
            multiPointHandler, // 4
            multiLineStringHandler, // 5
            multiPolygonHandler, // 6
        ];

        var end:Int = buf.length;
        while (cursor < end) {
            pushByteOrder(getInt8());
            var type:Int = getUint32();
            var handler:Dynamic->Dynamic = typeHandlers[type];
            assertNotStrictEqual(handler, null, 'unknown type');
            primitives.push(handler());
            popByteOrder();
        }

        return {
            envelope: envelope,
            primitives: primitives,
        };
    }
}

class BytesInput {
    var bytes:BytesData;
    var pos:Int;

    public function new(bytes:BytesData) {
        this.bytes = bytes;
        this.pos = 0;
    }

    public function readFloatBE(pos:Int):Float {
        var b1:Int = bytes.get(pos);
        var b2:Int = bytes.get(pos + 1);
        var b3:Int = bytes.get(pos + 2);
        var b4:Int = bytes.get(pos + 3);
        return Float.fromBits((b1 << 24) | (b2 << 16) | (b3 << 8) | b4);
    }

    public function readFloatLE(pos:Int):Float {
        var b1:Int = bytes.get(pos + 3);
        var b2:Int = bytes.get(pos + 2);
        var b3:Int = bytes.get(pos + 1);
        var b4:Int = bytes.get(pos);
        return Float.fromBits((b1 << 24) | (b2 << 16) | (b3 << 8) | b4);
    }

    public function readInt8(pos:Int):Int {
        return bytes.get(pos);
    }

    public function readUInt32BE(pos:Int):Int {
        var b1:Int = bytes.get(pos);
        var b2:Int = bytes.get(pos + 1);
        var b3:Int = bytes.get(pos + 2);
        var b4:Int = bytes.get(pos + 3);
        return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
    }

    public function readUInt32LE(pos:Int):Int {
        var b1:Int = bytes.get(pos + 3);
        var b2:Int = bytes.get(pos + 2);
        var b3:Int = bytes.get(pos + 1);
        var b4:Int = bytes.get(pos);
        return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
    }
}