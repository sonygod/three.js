package three.js.manual.resources.tools.geo_picking;

import js.lib.Promise;
import js.lib.Uint8Array;
import js.lib.ArrayBuffer;
import js.lib.DataView;
import js.lib.TextDecoder;

class Shapefile {
  static function open(shp:Dynamic, dbf:Dynamic, options:Dynamic):Promise<Shapefile> {
    if (Std.isOfType(dbf, String)) {
      if (!~/\.dbf$/.test(dbf)) dbf += ".dbf";
      dbf = Path.path(dbf);
    } else if (Std.isOfType(dbf, ArrayBuffer) || Std.isOfType(dbf, Uint8Array)) {
      dbf = array(dbf);
    } else {
      dbf = stream(dbf);
    }
    if (Std.isOfType(shp, String)) {
      if (!~/\.shp$/.test(shp)) shp += ".shp";
      if (dbf == null) dbf = Path.path(shp.substring(0, shp.length - 4) + ".dbf").catchError(function(_) {});
      shp = Path.path(shp);
    } else if (Std.isOfType(shp, ArrayBuffer) || Std.isOfType(shp, Uint8Array)) {
      shp = array(shp);
    } else {
      shp = stream(shp);
    }
    return Promise.all([shp, dbf]).then(function(sources) {
      var shp = sources[0], dbf = sources[1], encoding = "windows-1252";
      if (options != null && options.encoding != null) encoding = options.encoding;
      return shapefile(shp, dbf, dbf != null ? new TextDecoder(encoding) : null);
    });
  }

  static function openShp(source:Dynamic):Promise<Shp> {
    if (Std.isOfType(source, String)) {
      if (!~/\.shp$/.test(source)) source += ".shp";
      source = Path.path(source);
    } else if (Std.isOfType(source, ArrayBuffer) || Std.isOfType(source, Uint8Array)) {
      source = array(source);
    } else {
      source = stream(source);
    }
    return Promise.resolve(source).then(shp);
  }

  static function openDbf(source:Dynamic, options:Dynamic):Promise<Dbf> {
    var encoding = "windows-1252";
    if (options != null && options.encoding != null) encoding = options.encoding;
    encoding = new TextDecoder(encoding);
    if (Std.isOfType(source, String)) {
      if (!~/\.dbf$/.test(source)) source += ".dbf";
      source = Path.path(source);
    } else if (Std.isOfType(source, ArrayBuffer) || Std.isOfType(source, Uint8Array)) {
      source = array(source);
    } else {
      source = stream(source);
    }
    return Promise.resolve(source).then(function(source) {
      return dbf(source, encoding);
    });
  }

  static function read(shp:Dynamic, dbf:Dynamic, options:Dynamic):Promise<FeatureCollection> {
    return open(shp, dbf, options).then(function(source) {
      var features = [], collection = {type: "FeatureCollection", features: features, bbox: source.bbox};
      return source.read().then(function read(result) {
        if (result.done) return collection;
        features.push(result.value);
        return source.read().then(read);
      });
    });
  }
}

class Path {
  static function path(url:String):Promise<ArraySource> {
    return fetchPath(url);
  }
}

class ArraySource {
  var _array:Uint8Array;

  public function new(array:Uint8Array) {
    _array = array;
  }

  public function read():Promise<{done:Bool, value:Uint8Array}> {
    var array = _array;
    _array = null;
    return Promise.resolve({done: false, value: array});
  }

  public function cancel():Promise<Void> {
    return Promise.resolve();
  }
}

class SliceSource {
  var _source:ArraySource;
  var _array:Uint8Array;
  var _index:Int;

  public function new(source:ArraySource) {
    _source = source;
    _array = new Uint8Array(0);
    _index = 0;
  }

  public function read():Promise<{done:Bool, value:Uint8Array}> {
    var that = this, array = _array.subarray(_index);
    return _source.read().then(function(result) {
      _array = new Uint8Array(0);
      _index = 0;
      return result.done ? (array.length > 0 ? {done: false, value: array} : {done: true, value: undefined}) : {done: false, value: concat(array, result.value)};
    });
  }

  public function slice(length:Int):Promise<Uint8Array> {
    if ((length |= 0) < 0) throw new Error("invalid length");
    var that = this, index = _array.length - _index;

    // If the request fits within the remaining buffer, resolve it immediately.
    if (_index + length <= _array.length) {
      return Promise.resolve(_array.subarray(_index, _index += length));
    }

    // Otherwise, read chunks repeatedly until the request is fulfilled.
    var array = new Uint8Array(length);
    array.set(_array.subarray(_index));
    return (function read() {
      return _source.read().then(function(result) {
        if (result.done) {
          _array = new Uint8Array(0);
          _index = 0;
          return index > 0 ? array.subarray(0, index) : null;
        }

        if (index + result.value.length >= length) {
          _array = result.value;
          _index = length - index;
          array.set(result.value.subarray(0, length - index), index);
          return array;
        }

        array.set(result.value, index);
        index += result.value.length;
        return read();
      });
    })();
  }

  public function cancel():Promise<Void> {
    return _source.cancel();
  }
}

class Dbf {
  var _source:ArraySource;
  var _decode:TextDecoder;
  var _recordLength:Int;
  var _fields:Array<{name:String, type:String, length:Int}>;

  public function new(source:ArraySource, decoder:TextDecoder) {
    _source = source;
    _decode = decoder.decode.bind(decoder);
    _recordLength = 0;
    _fields = [];
  }

  public function read():Promise<{done:Bool, value:Dynamic}> {
    return _source.slice(_recordLength).then(function(array) {
      if (array == null) return {done: true, value: undefined};
      var head = new DataView(array.buffer, array.byteOffset, array.byteLength);
      _recordLength = head.getUint16(10, true);
      _fields = [];
      for (n in 0...head.getUint8(0)) {
        var j = 0;
        while (j < 11) if (head.getUint8(n + j) == 0) break;
        _fields.push({
          name: _decode(new Uint8Array(head.buffer, head.byteOffset + n, j)),
          type: String.fromCharCode(head.getUint8(n + 11)),
          length: head.getUint8(n + 16)
        });
      }
      return {done: false, value: _fields.reduce(function(p, f) {
        p[f.name] = types[f.type](_decode(f.length == 1 ? f.name : new Uint8Array(head.buffer, head.byteOffset + n, f.length)));
        return p;
      }, {})};
    });
  }

  public function cancel():Promise<Void> {
    return _source.cancel();
  }
}

class Shp {
  var _source:ArraySource;
  var _type:Int;
  var _index:Int;
  var _parse:Dynamic;

  public function new(source:ArraySource) {
    _source = source;
    _type = 0;
    _index = 0;
    _parse = null;
  }

  public function read():Promise<{done:Bool, value:Dynamic}> {
    ++_index;
    return _source.slice(12).then(function(array) {
      if (array == null) return {done: true, value: undefined};
      var header = new DataView(array.buffer, array.byteOffset, array.byteLength);
      var length = header.getInt32(4, false) * 2 - 4, type = header.getInt32(8, true);
      return length < 0 || (type && type != _type) ? skip() : read();
    });

    function skip():Promise<{done:Bool, value:Dynamic}> {
      return _source.slice(4).then(function(chunk) {
        if (chunk == null) return {done: true, value: undefined};
        var header = new DataView(concat(array.slice(4), chunk).buffer, array.byteOffset, array.byteLength);
        return header.getInt32(0, false) !== _index ? skip() : read();
      });
    }

    function read():Promise<{done:Bool, value:Dynamic}> {
      return _source.slice(length).then(function(chunk) {
        return {done: false, value: _parse(new DataView(concat(array.slice(8), chunk).buffer, array.byteOffset, array.byteLength))};
      });
    }
  }

  public function cancel():Promise<Void> {
    return _source.cancel();
  }
}

class Shapefile {
  var _shp:Shp;
  var _dbf:Dbf;
  var bbox:Array<Float>;

  public function new(shp:Shp, dbf:Dbf) {
    _shp = shp;
    _dbf = dbf;
    bbox = shp.bbox;
  }

  public function read():Promise<{done:Bool, value:Feature}> {
    return Promise.all([
      _dbf ? _dbf.read() : {value: {}},
      _shp.read()
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
      _dbf && _dbf.cancel(),
      _shp.cancel()
    ]).then(function(_) {});
  }
}

class Feature {
  public var type:String;
  public var properties:Dynamic;
  public var geometry:Dynamic;
}

class FeatureCollection {
  public var type:String;
  public var features:Array<Feature>;
  public var bbox:Array<Float>;
}

class TextDecoder {
  var encoding:String;

  public function new(encoding:String) {
    this.encoding = encoding;
  }

  public function decode(array:Uint8Array):String {
    return "";
  }
}

class XMLHttpRequest {
  public function new() {}

  public function open(method:String, url:String, async:Bool) {}

  public function send() {}

  public function getResponseHeader(name:String):String {
    return "";
  }

  public function getResponseType():String {
    return "";
  }

  public function getResponseText():String {
    return "";
  }
}

class Fetch {
  public static function fetch(url:String):Promise<ArrayBuffer> {
    return null;
  }
}

class FetchPath {
  public static function path(url:String):Promise<ArraySource> {
    return Fetch.fetch(url).then(array);
  }
}

class ARRAY_CANCEL {
  public function cancel():Promise<Void> {
    return Promise.resolve();
  }
}

class PATH_CANCEL {
  public function cancel():Promise<Void> {
    return Promise.resolve();
  }
}