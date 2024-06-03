class ogcParser {
    public static function parse(buf:haxe.io.Bytes):Dynamic {
        if (buf.get(0) != 0x47 || buf.get(1) != 0x50) throw new Error("bad header");
        if (buf.get(2) != 0) throw new Error("unknown version");

        var flags = buf.get(3);
        var flag_x = (flags >> 5) & 1;
        if (flag_x != 0) throw new Error("x must be 0");

        var flag_byteOrder = (flags >> 0) & 1;
        var flag_envelope = (flags >> 1) & 7;

        var envelopeSizes = [
            0, // 0: non
            4, // 1: minx, maxx, miny, maxy
            6, // 2: minx, maxx, miny, maxy, minz, maxz
            6, // 3: minx, maxx, miny, maxy, minm, maxm
            8, // 4: minx, maxx, miny, maxy, minz, maxz, minm, maxm
        ];

        var envelopeSize = envelopeSizes[flag_envelope];
        if (envelopeSize == null) throw new Error("unknown envelope size");

        var cursor = 8;
        var dataView = new haxe.io.BytesInput(buf.sub(cursor, envelopeSize * 8));
        dataView.setBigEndian(!flag_byteOrder);

        var envelope:Array<Float> = [];
        for (i in 0...envelopeSize) {
            envelope.push(dataView.readFloat64());
        }

        cursor += envelopeSize * 8;
        dataView = new haxe.io.BytesInput(buf.sub(cursor));
        dataView.setBigEndian(!flag_byteOrder);

        var primitives = [];

        function getPoints(num:Int):Array<Float> {
            var points:Array<Float> = [];
            for (i in 0...num) {
                points.push(dataView.readFloat64());
                points.push(dataView.readFloat64());
            }
            return points;
        }

        function getRings(num:Int):Array<Array<Float>> {
            var rings:Array<Array<Float>> = [];
            for (i in 0...num) {
                var numPoints = dataView.readUInt32();
                rings.push(getPoints(numPoints));
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
            var numPoints = dataView.readUInt32();
            return {
                type: 'lineString',
                points: getPoints(numPoints),
            };
        }

        function polygonHandler():Dynamic {
            var numRings = dataView.readUInt32();
            return {
                type: 'polygon',
                rings: getRings(numRings),
            };
        }

        function multiPointHandler():Dynamic {
            var numPoints = dataView.readUInt32();
            var points:Array<Float> = [];
            for (i in 0...numPoints) {
                dataView.setBigEndian(!dataView.readByte());
                var type = dataView.readUInt32();
                if (type != 1) throw new Error("type must be 1");
                points.push(dataView.readFloat64());
                points.push(dataView.readFloat64());
                dataView.setBigEndian(!flag_byteOrder);
            }
            return {
                type: 'multiPoint',
                points: points,
            };
        }

        function multiLineStringHandler():Dynamic {
            var numLineStrings = dataView.readUInt32();
            var lineStrings:Array<Array<Float>> = [];
            for (i in 0...numLineStrings) {
                dataView.setBigEndian(!dataView.readByte());
                var type = dataView.readUInt32();
                if (type != 2) throw new Error("type must be 2");
                var numPoints = dataView.readUInt32();
                lineStrings.push(getPoints(numPoints));
                dataView.setBigEndian(!flag_byteOrder);
            }
            return {
                type: 'multiLineString',
                lineStrings: lineStrings,
            };
        }

        function multiPolygonHandler():Dynamic {
            var numPolygons = dataView.readUInt32();
            var polygons:Array<Array<Array<Float>>> = [];
            for (i in 0...numPolygons) {
                dataView.setBigEndian(!dataView.readByte());
                var type = dataView.readUInt32();
                if (type != 3) throw new Error("type must be 3");
                var numRings = dataView.readUInt32();
                polygons.push(getRings(numRings));
                dataView.setBigEndian(!flag_byteOrder);
            }
            return {
                type: 'multiPolygon',
                polygons: polygons,
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

        while (dataView.getBytesAvailable() > 0) {
            dataView.setBigEndian(!dataView.readByte());
            var type = dataView.readUInt32();
            var handler = typeHandlers[type];
            if (handler == null) throw new Error("unknown type");
            primitives.push(handler());
        }

        return {
            envelope: envelope,
            primitives: primitives,
        };
    }
}