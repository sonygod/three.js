package three.js.manual.resources.tools.geo_picking;

import js.Promise;
import js.html.ArrayBuffer;
import js.html.Uint8Array;
import js.html.DataView;

class Shapefile {
    public static function open(shp:String, dbf:String, options:Dynamic = null):Promise<Shapefile> {
        if (!/\.shp$/.test(shp)) shp += ".shp";
        if (!/\.dbf$/.test(dbf)) dbf += ".dbf";
        var shpPromise:Promise<ArrayBuffer> = path(shp);
        var dbfPromise:Promise<ArrayBuffer> = path(dbf);
        return Promise.all([shpPromise, dbfPromise]).then(function(sources:Array<ArrayBuffer>):Shapefile {
            var shp:Shp = new Shp(sources[0]);
            var dbf:Dbf = new Dbf(sources[1]);
            return new Shapefile(shp, dbf);
        });
    }

    public static function openShp(source:String):Promise<Shp> {
        if (!/\.shp$/.test(source)) source += ".shp";
        var sourcePromise:Promise<ArrayBuffer> = path(source);
        return sourcePromise.then(function(buffer:ArrayBuffer):Shp {
            return new Shp(buffer);
        });
    }

    public static function openDbf(source:String, options:Dynamic = null):Promise<Dbf> {
        if (!/\.dbf$/.test(source)) source += ".dbf";
        var sourcePromise:Promise<ArrayBuffer> = path(source);
        var encoding:String = "windows-1252";
        if (options != null && options.encoding != null) encoding = options.encoding;
        return sourcePromise.then(function(buffer:ArrayBuffer):Dbf {
            return new Dbf(buffer, new TextDecoder(encoding));
        });
    }

    public static function read(shp:String, dbf:String, options:Dynamic = null):Promise<Dynamic> {
        return open(shp, dbf, options).then(function(source:Shapefile):Dynamic {
            var features:Array<Dynamic> = [];
            var collection:Dynamic = {type: "FeatureCollection", features: features, bbox: source.bbox};
            return source.read().then(function read(result:Dynamic):Dynamic {
                if (result.done) return collection;
                features.push(result.value);
                return source.read().then(read);
            });
        });
    }
}

class Shp {
    public var _source:ArrayBuffer;
    public var _type:Int;
    public var _index:Int;
    public var _parse:Dynamic;
    public var bbox:Array<Float>;

    public function new(buffer:ArrayBuffer) {
        _source = buffer;
        var header:DataView = new DataView(buffer);
        _type = header.getUint32(32, true);
        _index = 0;
        _parse = parsers[_type];
        bbox = [header.getFloat64(36, true), header.getFloat64(44, true), header.getFloat64(52, true), header.getFloat64(60, true)];
    }

    public function read():Promise<Dynamic> {
        return Promise.all([_source.slice(12)]).then(function(chunks:Array<ArrayBuffer>):Dynamic {
            var header:DataView = new DataView(chunks[0]);
            if (header.getInt32(0, false) !== _index) {
                // skip invalid record
                return read();
            }
            var length:Int = header.getInt32(4, false) * 2 - 4;
            return _source.slice(length).then(function(chunk:ArrayBuffer):Dynamic {
                var content:Uint8Array = new Uint8Array(_source.byteLength - 8);
                content.set(new Uint8Array(chunks[0].slice(8)));
                content.set(new Uint8Array(chunk), content.length - chunk.byteLength);
                return {done: false, value: _parse(content)};
            });
        });
    }
}

class Dbf {
    public var _source:ArrayBuffer;
    public var _decode:TextDecoder;
    public var _recordLength:Int;
    public var _fields:Array<Dynamic>;

    public function new(buffer:ArrayBuffer, decoder:TextDecoder) {
        _source = buffer;
        _decode = decoder;
        var header:DataView = new DataView(buffer);
        _recordLength = header.getUint16(10, true);
        _fields = [];
        for (var n:Int = 0; ; n += 32) {
            if (header.getUint8(n) == 0x0d) break;
            var name:String = _decode.decode(new Uint8Array(buffer, n, 11));
            var type:String = String.fromCharCode(header.getUint8(n + 11));
            var length:Int = header.getUint8(n + 16);
            _fields.push({name: name, type: type, length: length});
        }
    }

    public function read():Promise<Dynamic> {
        return _source.slice(32).then(function(array:ArrayBuffer):Dynamic {
            var buffer:Uint8Array = new Uint8Array(array);
            return {done: false, value: _fields.reduce(function(p:Dynamic, f:Dynamic):Dynamic {
                p[f.name] = types[f.type](buffer.subarray(0, f.length));
                return p;
            }, {})};
        });
    }
}

class Shapefile {
    public var _shp:Shp;
    public var _dbf:Dbf;
    public var bbox:Array<Float>;

    public function new(shp:Shp, dbf:Dbf) {
        _shp = shp;
        _dbf = dbf;
        bbox = shp.bbox;
    }

    public function read():Promise<Dynamic> {
        return Promise.all([_shp.read(), _dbf.read()]).then(function(results:Array<Dynamic>):Dynamic {
            if (results[0].done) return {done: true, value: null};
            return {done: false, value: {
                type: "Feature",
                properties: results[1].value,
                geometry: results[0].value
            }};
        });
    }
}