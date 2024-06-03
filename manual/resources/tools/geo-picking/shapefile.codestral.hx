// https://github.com/mbostock/shapefile Version 0.6.6. Copyright 2017 Mike Bostock.
import js.Browser.document;
import js.Fetch;
import js.xml.XMLHttpRequest;
import js.ArrayBuffer;
import js.Promise;
import js.Array;
import js.lib.ArrayBufferView;
import js.lib.DataView;

class ArraySource {
    private var _array:js.ArrayBufferView<Uint8>;

    public function new(array:js.ArrayBufferView<Uint8>) {
        this._array = array;
    }

    public function read():Promise<{done:Bool, value:js.ArrayBufferView<Uint8>}> {
        var array = this._array;
        this._array = null;
        return Promise.resolve(array != null ? {done: false, value: array} : {done: true, value: null});
    }

    public function cancel():Promise<Void> {
        this._array = null;
        return Promise.resolve();
    }
}

class SliceSource {
    private var _source:js.lib.ReadableStreamReader<Uint8Array>;
    private var _array:js.ArrayBufferView<Uint8> = new Uint8Array(0);
    private var _index:Int = 0;

    public function new(source:js.lib.ReadableStreamReader<Uint8Array>) {
        this._source = source;
    }

    public function read():Promise<{done:Bool, value:js.ArrayBufferView<Uint8>}> {
        var array = this._array.subarray(this._index);
        return this._source.read().then(function(result) {
            this._array = new Uint8Array(0);
            this._index = 0;
            return result.done ? (array.length > 0
                ? {done: false, value: array}
                : {done: true, value: null})
                : {done: false, value: concat(array, result.value)};
        }.bind(this));
    }

    public function slice(length:Int):Promise<js.ArrayBufferView<Uint8>> {
        length |= 0;
        if (length < 0) throw new Error("invalid length");
        var index = this._array.length - this._index;

        if (this._index + length <= this._array.length) {
            return Promise.resolve(this._array.subarray(this._index, this._index += length));
        }

        var array = new Uint8Array(length);
        array.set(this._array.subarray(this._index));
        return (function read() {
            return this._source.read().then(function(result) {
                if (result.done) {
                    this._array = new Uint8Array(0);
                    this._index = 0;
                    return index > 0 ? array.subarray(0, index) : null;
                }

                if (index + result.value.length >= length) {
                    this._array = result.value;
                    this._index = length - index;
                    array.set(result.value.subarray(0, length - index), index);
                    return array;
                }

                array.set(result.value, index);
                index += result.value.length;
                return read();
            }.bind(this));
        }.bind(this))();
    }

    public function cancel():Promise<Void> {
        return this._source.cancel();
    }
}

class Dbf {
    private var _source:SliceSource;
    private var _decode:(js.ArrayBufferView<Uint8>) -> String;
    private var _recordLength:Int;
    private var _fields:Array<{name:String, type:String, length:Int}>;

    public function new(source:SliceSource, decoder:js.lib.TextDecoder, head:js.lib.DataView, body:js.lib.DataView) {
        this._source = source;
        this._decode = decoder.decode.bind(decoder);
        this._recordLength = head.getUint16(10, true);
        this._fields = [];
        for (var n = 0; body.getUint8(n) != 0x0d; n += 32) {
            var nameLength = 0;
            while (nameLength < 11 && body.getUint8(n + nameLength) != 0) nameLength++;
            this._fields.push({
                name: this._decode(new Uint8Array(body.buffer, body.byteOffset + n, nameLength)),
                type: String.fromCharCode(body.getUint8(n + 11)),
                length: body.getUint8(n + 16)
            });
        }
    }

    public function read():Promise<{done:Bool, value:Dynamic}> {
        var i = 1;
        return this._source.slice(this._recordLength).then(function(value) {
            return value != null && value[0] != 0x1a ? {done: false, value: this._fields.reduce(function(p, f) {
                p[f.name] = readValue(f.type, this._decode(value.subarray(i, i += f.length)));
                return p;
            }.bind(this), {})} : {done: true, value: null};
        }.bind(this));
    }

    public function cancel():Promise<Void> {
        return this._source.cancel();
    }
}

class Shp {
    private var _source:SliceSource;
    private var _type:Int;
    private var _index:Int = 0;
    private var _parse:(js.lib.DataView) -> Dynamic;
    public var bbox:Array<Float>;

    public function new(source:SliceSource, header:js.lib.DataView) {
        var type = header.getInt32(32, true);
        if (!hasOwnProperty(parsers, type)) throw new Error("unsupported shape type: " + type);
        this._source = source;
        this._type = type;
        this._parse = parsers[type];
        this.bbox = [header.getFloat64(36, true), header.getFloat64(44, true), header.getFloat64(52, true), header.getFloat64(60, true)];
    }

    public function read():Promise<{done:Bool, value:Dynamic}> {
        this._index++;
        return this._source.slice(12).then(function(array) {
            if (array == null) return {done: true, value: null};
            var header = new DataView(array.buffer, array.byteOffset, array.byteLength);

            function skip() {
                return this._source.slice(4).then(function(chunk) {
                    if (chunk == null) return {done: true, value: null};
                    header = new DataView(array = concat(array.subarray(4), chunk)).buffer;
                    return header.getInt32(0, false) != this._index ? skip() : read();
                }.bind(this));
            }

            function read() {
                var length = header.getInt32(4, false) * 2 - 4, type = header.getInt32(8, true);
                return length < 0 || (type != 0 && type != this._type) ? skip() : this._source.slice(length).then(function(chunk) {
                    return {done: false, value: type != 0 ? this._parse(new DataView(concat(array.subarray(8), chunk).buffer)) : null};
                }.bind(this));
            }

            return read();
        }.bind(this));
    }

    public function cancel():Promise<Void> {
        return this._source.cancel();
    }
}

class Shapefile {
    private var _shp:Shp;
    private var _dbf:Dbf;
    public var bbox:Array<Float>;

    public function new(shp:Shp, dbf:Dbf) {
        this._shp = shp;
        this._dbf = dbf;
        this.bbox = shp.bbox;
    }

    public function read():Promise<{done:Bool, value:{type:String, properties:Dynamic, geometry:Dynamic}}> {
        return Promise.all([
            this._dbf != null ? this._dbf.read() : {value: {}},
            this._shp.read()
        ]).then(function(results) {
            var dbf = results[0], shp = results[1];
            return shp.done ? shp : {
                done: false,
                value: {
                    type: "Feature",
                    properties: dbf.value,
                    geometry: shp.value
                }
            };
        });
    }

    public function cancel():Promise<Void> {
        return Promise.all([
            this._dbf != null ? this._dbf.cancel() : Promise.resolve(),
            this._shp.cancel()
        ]);
    }
}

function array(array:js.ArrayBufferView<Uint8>):ArraySource {
    return new ArraySource(array instanceof Uint8Array ? array : new Uint8Array(array));
}

function slice(source:Dynamic):SliceSource {
    if (js.Boot.hasField(source, "slice")) return source;
    return new SliceSource(js.Boot.hasField(source, "read") ? source : source.getReader());
}

function dbf(source:Dynamic, decoder:js.lib.TextDecoder):Promise<Dbf> {
    source = slice(source);
    return source.slice(32).then(function(array) {
        return source.slice(new DataView(array.buffer, array.byteOffset, array.byteLength).getUint16(8, true) - 32).then(function(array) {
            return new Dbf(source, decoder, new DataView(array.buffer, array.byteOffset, array.byteLength), new DataView(array.buffer, array.byteOffset, array.byteLength));
        });
    });
}

function shp(source:Dynamic):Promise<Shp> {
    source = slice(source);
    return source.slice(100).then(function(array) {
        return new Shp(source, new DataView(array.buffer, array.byteOffset, array.byteLength));
    });
}

function shapefile(shpSource:Dynamic, dbfSource:Dynamic, decoder:js.lib.TextDecoder):Promise<Shapefile> {
    return Promise.all([
        shp(shpSource),
        dbfSource != null ? dbf(dbfSource, decoder) : Promise.resolve(null)
    ]).then(function(sources) {
        return new Shapefile(sources[0], sources[1]);
    });
}

function open(shpSource:Dynamic, dbfSource:Dynamic, options:Dynamic):Promise<Shapefile> {
    if (Std.is(dbfSource, String)) {
        if (!dbfSource.endsWith(".dbf")) dbfSource += ".dbf";
        dbfSource = path(dbfSource);
    } else if (Std.is(dbfSource, js.ArrayBuffer) || Std.is(dbfSource, Uint8Array)) {
        dbfSource = array(dbfSource);
    } else if (dbfSource != null) {
        dbfSource = stream(dbfSource);
    }

    if (Std.is(shpSource, String)) {
        if (!shpSource.endsWith(".shp")) shpSource += ".shp";
        if (dbfSource == null) dbfSource = path(shpSource.substring(0, shpSource.length - 4) + ".dbf").catch(function(e) { return null; });
        shpSource = path(shpSource);
    } else if (Std.is(shpSource, js.ArrayBuffer) || Std.is(shpSource, Uint8Array)) {
        shpSource = array(shpSource);
    } else {
        shpSource = stream(shpSource);
    }

    return Promise.all([shpSource, dbfSource]).then(function(sources) {
        var shpSource = sources[0], dbfSource = sources[1], encoding = "windows-1252";
        if (options != null && options.encoding != null) encoding = options.encoding;
        return shapefile(shpSource, dbfSource, dbfSource != null ? new TextDecoder(encoding) : null);
    });
}

function openShp(source:Dynamic):Promise<Shp> {
    if (Std.is(source, String)) {
        if (!source.endsWith(".shp")) source += ".shp";
        source = path(source);
    } else if (Std.is(source, js.ArrayBuffer) || Std.is(source, Uint8Array)) {
        source = array(source);
    } else {
        source = stream(source);
    }
    return Promise.resolve(source).then(shp);
}

function openDbf(source:Dynamic, options:Dynamic):Promise<Dbf> {
    var encoding = "windows-1252";
    if (options != null && options.encoding != null) encoding = options.encoding;
    encoding = new TextDecoder(encoding);
    if (Std.is(source, String)) {
        if (!source.endsWith(".dbf")) source += ".dbf";
        source = path(source);
    } else if (Std.is(source, js.ArrayBuffer) || Std.is(source, Uint8Array)) {
        source = array(source);
    } else {
        source = stream(source);
    }
    return Promise.resolve(source).then(function(source) {
        return dbf(source, encoding);
    });
}

function read(shpSource:Dynamic, dbfSource:Dynamic, options:Dynamic):Promise<{type:String, features:Array<{type:String, properties:Dynamic, geometry:Dynamic}>, bbox:Array<Float>}> {
    return open(shpSource, dbfSource, options).then(function(source) {
        var features = [];
        var collection = {type: "FeatureCollection", features: features, bbox: source.bbox};
        return source.read().then(function read(result) {
            if (result.done) return collection;
            features.push(result.value);
            return source.read().then(read);
        });
    });
}

function path(p:String):Promise<ArraySource> {
    if (js.Browser.window.fetch != null) {
        return Fetch.fetch(p).then(function(response) {
            return response.body != null && response.body.getReader != null
                ? response.body.getReader()
                : response.arrayBuffer().then(array);
        });
    } else {
        return new Promise(function(resolve, reject) {
            var request = new XMLHttpRequest();
            request.responseType = "arraybuffer";
            request.onload = function() { resolve(array(request.response)); };
            request.onerror = reject;
            request.ontimeout = reject;
            request.open("GET", p, true);
            request.send();
        });
    }
}

function stream(source:Dynamic):js.lib.ReadableStreamReader<Uint8Array> {
    return js.Boot.hasField(source, "read") ? source : source.getReader();
}

function concat(a:js.ArrayBufferView<Uint8>, b:js.ArrayBufferView<Uint8>):js.ArrayBufferView<Uint8> {
    if (a.length == 0) return b;
    if (b.length == 0) return a;
    var c = new Uint8Array(a.length + b.length);
    c.set(a);
    c.set(b, a.length);
    return c;
}

function readValue(type:String, value:String):Dynamic {
    switch (type) {
        case "B":
        case "F":
        case "M":
        case "N":
            if (value == null || value.trim().length == 0 || isNaN(+value)) return null;
            return +value;
        case "C":
            return value.trim().length > 0 ? value.trim() : null;
        case "D":
            return new Date(+value.substring(0, 4), +value.substring(4, 6) - 1, +value.substring(6, 8));
        case "L":
            if (/^[nf]$/i.test(value)) return false;
            if (/^[yt]$/i.test(value)) return true;
            return null;
        default:
            return null;
    }
}

var parsers = {
    0: (function(record:js.lib.DataView):Dynamic { return null; }),
    1: (function(record:js.lib.DataView):Dynamic { return {type: "Point", coordinates: [record.getFloat64(4, true), record.getFloat64(12, true)]}; }),
    3: (function(record:js.lib.DataView):Dynamic {
        var i = 44, j, n = record.getInt32(36, true), m = record.getInt32(40, true), parts = new Array<Int>(), points = new Array<Array<Float>>();
        for (j = 0; j < n; ++j, i += 4) parts.push(record.getInt32(i, true));
        for (j = 0; j < m; ++j, i += 16) points.push([record.getFloat64(i, true), record.getFloat64(i + 8, true)]);
        return n == 1
            ? {type: "LineString", coordinates: points}
            : {type: "MultiLineString", coordinates: parts.map(function(i, j) { return points.slice(i, parts[j + 1]); })};
    }),
    5: (function(record:js.lib.DataView):Dynamic {
        var i = 44, j, n = record.getInt32(36, true), m = record.getInt32(40, true), parts = new Array<Int>(), points = new Array<Array<Float>>(), polygons = [], holes = [];
        for (j = 0; j < n; ++j, i += 4) parts.push(record.getInt32(i, true));
        for (j = 0; j < m; ++j, i += 16) points.push([record.getFloat64(i, true), record.getFloat64(i + 8, true)]);

        parts.forEach(function(i, j) {
            var ring = points.slice(i, parts[j + 1]);
            if (ringClockwise(ring)) polygons.push([ring]);
            else holes.push(ring);
        });

        holes.forEach(function(hole) {
            polygons.some(function(polygon) {
                if (ringContainsSome(polygon[0], hole)) {
                    polygon.push(hole);
                    return true;
                }
            }) || polygons.push([hole]);
        });

        return polygons.length == 1
            ? {type: "Polygon", coordinates: polygons[0]}
            : {type: "MultiPolygon", coordinates: polygons};
    }),
    8: (function(record:js.lib.DataView):Dynamic {
        var i = 40, j, n = record.getInt32(36, true), coordinates = new Array<Array<Float>>();
        for (j = 0; j < n; ++j, i += 16) coordinates.push([record.getFloat64(i, true), record.getFloat64(i + 8, true)]);
        return {type: "MultiPoint", coordinates: coordinates};
    }),
    11: (function(record:js.lib.DataView):Dynamic { return {type: "Point", coordinates: [record.getFloat64(4, true), record.getFloat64(12, true)]}; }),
    13: (function(record:js.lib.DataView):Dynamic {
        var i = 44, j, n = record.getInt32(36, true), m = record.getInt32(40, true), parts = new Array<Int>(), points = new Array<Array<Float>>();
        for (j = 0; j < n; ++j, i += 4) parts.push(record.getInt32(i, true));
        for (j = 0; j < m; ++j, i += 16) points.push([record.getFloat64(i, true), record.getFloat64(i + 8, true)]);
        return n == 1
            ? {type: "LineString", coordinates: points}
            : {type: "MultiLineString", coordinates: parts.map(function(i, j) { return points.slice(i, parts[j + 1]); })};
    }),
    15: (function(record:js.lib.DataView):Dynamic {
        var i = 44, j, n = record.getInt32(36, true), m = record.getInt32(40, true), parts = new Array<Int>(), points = new Array<Array<Float>>(), polygons = [], holes = [];
        for (j = 0; j < n; ++j, i += 4) parts.push(record.getInt32(i, true));
        for (j = 0; j < m; ++j, i += 16) points.push([record.getFloat64(i, true), record.getFloat64(i + 8, true)]);

        parts.forEach(function(i, j) {
            var ring = points.slice(i, parts[j + 1]);
            if (ringClockwise(ring)) polygons.push([ring]);
            else holes.push(ring);
        });

        holes.forEach(function(hole) {
            polygons.some(function(polygon) {
                if (ringContainsSome(polygon[0], hole)) {
                    polygon.push(hole);
                    return true;
                }
            }) || polygons.push([hole]);
        });

        return polygons.length == 1
            ? {type: "Polygon", coordinates: polygons[0]}
            : {type: "MultiPolygon", coordinates: polygons};
    }),
    18: (function(record:js.lib.DataView):Dynamic {
        var i = 40, j, n = record.getInt32(36, true), coordinates = new Array<Array<Float>>();
        for (j = 0; j < n; ++j, i += 16) coordinates.push([record.getFloat64(i, true), record.getFloat64(i + 8, true)]);
        return {type: "MultiPoint", coordinates: coordinates};
    }),
    21: (function(record:js.lib.DataView):Dynamic { return {type: "Point", coordinates: [record.getFloat64(4, true), record.getFloat64(12, true)]}; }),
    23: (function(record:js.lib.DataView):Dynamic {
        var i = 44, j, n = record.getInt32(36, true), m = record.getInt32(40, true), parts = new Array<Int>(), points = new Array<Array<Float>>();
        for (j = 0; j < n; ++j, i += 4) parts.push(record.getInt32(i, true));
        for (j = 0; j < m; ++j, i += 16) points.push([record.getFloat64(i, true), record.getFloat64(i + 8, true)]);
        return n == 1
            ? {type: "LineString", coordinates: points}
            : {type: "MultiLineString", coordinates: parts.map(function(i, j) { return points.slice(i, parts[j + 1]); })};
    }),
    25: (function(record:js.lib.DataView):Dynamic {
        var i = 44, j, n = record.getInt32(36, true), m = record.getInt32(40, true), parts = new Array<Int>(), points = new Array<Array<Float>>(), polygons = [], holes = [];
        for (j = 0; j < n; ++j, i += 4) parts.push(record.getInt32(i, true));
        for (j = 0; j < m; ++j, i += 16) points.push([record.getFloat64(i, true), record.getFloat64(i + 8, true)]);

        parts.forEach(function(i, j) {
            var ring = points.slice(i, parts[j + 1]);
            if (ringClockwise(ring)) polygons.push([ring]);
            else holes.push(ring);
        });

        holes.forEach(function(hole) {
            polygons.some(function(polygon) {
                if (ringContainsSome(polygon[0], hole)) {
                    polygon.push(hole);
                    return true;
                }
            }) || polygons.push([hole]);
        });

        return polygons.length == 1
            ? {type: "Polygon", coordinates: polygons[0]}
            : {type: "MultiPolygon", coordinates: polygons};
    }),
    28: (function(record:js.lib.DataView):Dynamic {
        var i = 40, j, n = record.getInt32(36, true), coordinates = new Array<Array<Float>>();
        for (j = 0; j < n; ++j, i += 16) coordinates.push([record.getFloat64(i, true), record.getFloat64(i + 8, true)]);
        return {type: "MultiPoint", coordinates: coordinates};
    })
};

function ringClockwise(ring:Array<Array<Float>>):Bool {
    var n = ring.length;
    if (n < 4) return false;
    var i = 0, area = ring[n - 1][1] * ring[0][0] - ring[n - 1][0] * ring[0][1];
    while (++i < n) area += ring[i - 1][1] * ring[i][0] - ring[i - 1][0] * ring[i][1];
    return area >= 0;
}

function ringContainsSome(ring:Array<Array<Float>>, hole:Array<Array<Float>>):Bool {
    var i = -1, n = hole.length, c;
    while (++i < n) {
        if (c = ringContains(ring, hole[i])) {
            return c > 0;
        }
    }
    return false;
}

function ringContains(ring:Array<Array<Float>>, point:Array<Float>):Int {
    var x = point[0], y = point[1], contains = -1;
    for (var i = 0, n = ring.length, j = n - 1; i < n; j = i++) {
        var pi = ring[i], xi = pi[0], yi = pi[1],
            pj = ring[j], xj = pj[0], yj = pj[1];
        if (segmentContains(pi, pj, point)) {
            return 0;
        }
        if (((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
            contains = -contains;
        }
    }
    return contains;
}

function segmentContains(p0:Array<Float>, p1:Array<Float>, p2:Array<Float>):Bool {
    var x20 = p2[0] - p0[0], y20 = p2[1] - p0[1];
    if (x20 == 0 && y20 == 0) return true;
    var x10 = p1[0] - p0[0], y10 = p1[1] - p0[1];
    if (x10 == 0 && y10 == 0) return false;
    var t = (x20 * x10 + y20 * y10) / (x10 * x10 + y10 * y10);
    return t < 0 || t > 1 ? false : t == 0 || t == 1 ? true : t * x10 == x20 && t * y10 == y20;
}

exports.open = open;
exports.openShp = openShp;
exports.openDbf = openDbf;
exports.read = read;