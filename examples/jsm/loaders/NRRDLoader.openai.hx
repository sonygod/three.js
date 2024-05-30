(package three.js.examples.jsm.loaders;

import three.js.loaders.FileLoader;
import three.js.loaders.Loader;
import three.js.Matrix4;
import three.js.Vector3;
import js.html.Uint8Array;
import js.html.Uint16Array;
import js.html.Uint32Array;
import js.html.Float32Array;
import js.html.Float64Array;
import js.html.Int8Array;
import js.html.Int16Array;
import js.html.Int32Array;
import Volume;

class NRRDLoader extends Loader {
    public var segmentation:Bool;

    public function new(manager:Loader) {
        super(manager);
    }

    public function load(url:String, onLoad:Volume->Void, onProgress:ProgressEvent->Void, onError:Error->Void) {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(data:ArrayBuffer) {
            try {
                onLoad(parse(data));
            } catch (e:Error) {
                if (onError != null) {
                    onError(e);
                } else {
                    Console.error(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function setSegmentation(segmentation:Bool) {
        this.segmentation = segmentation;
    }

    private function parse(data:ArrayBuffer):Volume {
        var _data = new Uint8Array(data);
        var _dataPointer = 0;
        var _nativeLittleEndian = new Int8Array(new Int16Array([1]).buffer)[0] > 0;
        var _littleEndian = true;

        var headerObject = {};

        function scan(type:String, chunks:Int):Dynamic {
            var _chunkSize = 1;
            var _array_type:Dynamic;

            switch (type) {
                case 'uchar':
                    break;
                case 'schar':
                    _array_type = Int8Array;
                    break;
                case 'ushort':
                    _array_type = Uint16Array;
                    _chunkSize = 2;
                    break;
                case 'sshort':
                    _array_type = Int16Array;
                    _chunkSize = 2;
                    break;
                case 'uint':
                    _array_type = Uint32Array;
                    _chunkSize = 4;
                    break;
                case 'sint':
                    _array_type = Int32Array;
                    _chunkSize = 4;
                    break;
                case 'float':
                    _array_type = Float32Array;
                    _chunkSize = 4;
                    break;
                case 'complex':
                    _array_type = Float64Array;
                    _chunkSize = 8;
                    break;
                case 'double':
                    _array_type = Float64Array;
                    _chunkSize = 8;
                    break;
            }

            var _bytes = new _array_type(_data.subarray(_dataPointer, _dataPointer += chunks * _chunkSize));

            if (_nativeLittleEndian != _littleEndian) {
                _bytes = flipEndianness(_bytes, _chunkSize);
            }

            return _bytes;
        }

        function flipEndianness(array:Dynamic, chunkSize:Int):Dynamic {
            var u8 = new Uint8Array(array.buffer, array.byteOffset, array.byteLength);
            for (i in 0...array.byteLength step chunkSize) {
                for (j in i + chunkSize - 1...i) {
                    var tmp = u8[j];
                    u8[j] = u8[k];
                    u8[k] = tmp;
                }
            }
            return array;
        }

        function parseHeader(header:String) {
            var lines = header.split(/\r?\n/);
            for (i in 0...lines.length) {
                var l = lines[i];
                if (l.match(/NRRD\d+/) != null) {
                    headerObject.isNrrd = true;
                } else if (!l.match(/^#/)) {
                    var m = l.match(/(.*):(.*)/);
                    var field = m[1].trim();
                    var data = m[2].trim();
                    var fn = _fieldFunctions[field];
                    if (fn != null) {
                        fn.call(headerObject, data);
                    } else {
                        Reflect.setField(headerObject, field, data);
                    }
                }
            }

            if (!headerObject.isNrrd) {
                throw new Error('Not an NRRD file');
            }

            if (headerObject.encoding == 'bz2' || headerObject.encoding == 'bzip2') {
                throw new Error('Bzip is not supported');
            }

            if (headerObject.vectors == null) {
                headerObject.vectors = [];
                headerObject.vectors.push([1, 0, 0]);
                headerObject.vectors.push([0, 1, 0]);
                headerObject.vectors.push([0, 0, 1]);

                if (headerObject.spacings != null) {
                    for (i in 0...3) {
                        if (!Math.isNaN(headerObject.spacings[i])) {
                            for (j in 0...3) {
                                headerObject.vectors[i][j] *= headerObject.spacings[i];
                            }
                        }
                    }
                }
            }
        }

        function parseDataAsText(data:ArrayBuffer, start:Int = 0, end:Int = data.byteLength):Dynamic {
            var number = '';
            var result = new headerObject.__array(headerObject.sizes.reduce(function(a, b) {
                return a * b;
            }, 1));
            var resultIndex = 0;
            var parsingFunction = parseInt;
            if (headerObject.__array == Float32Array || headerObject.__array == Float64Array) {
                parsingFunction = parseFloat;
            }

            for (i in start...end) {
                var value = data[i];
                if (value < 9 || value > 13 && value != 32) {
                    number += String.fromCharCode(value);
                } else {
                    if (number != '') {
                        result[resultIndex] = parsingFunction(number, 10);
                        resultIndex++;
                    }
                    number = '';
                }
            }

            if (number != '') {
                result[resultIndex] = parsingFunction(number, 10);
            }

            return result;
        }

        var _bytes = scan('uchar', data.byteLength);
        var _length = _bytes.length;
        var _header = null;
        var _data_start = 0;
        for (i in 1..._length) {
            if (_bytes[i - 1] == 10 && _bytes[i] == 10) {
                _header = parseChars(_bytes, 0, i - 2);
                _data_start = i + 1;
                break;
            }
        }

        parseHeader(_header);

        _data = new Uint8Array(data).subarray(_data_start);

        if (headerObject.encoding.substring(0, 2) == 'gz') {
            _data = fflate.gunzipSync(new Uint8Array(_data));
        } else if (headerObject.encoding == 'ascii' || headerObject.encoding == 'text' || headerObject.encoding == 'txt' || headerObject.encoding == 'hex') {
            _data = parseDataAsText(_data);
        } else if (headerObject.encoding == 'raw') {
            var _copy = new Uint8Array(_data.length);
            for (i in 0..._data.length) {
                _copy[i] = _data[i];
            }
            _data = _copy;
        }

        _data = _data.buffer;

        var volume = new Volume();
        volume.header = headerObject;
        volume.segmentation = this.segmentation;

        volume.data = new headerObject.__array(_data);

        // ...
    }

    private function parseChars(array:Uint8Array, start:Int = 0, end:Int = array.length):String {
        var output = '';
        for (i in start...end) {
            output += String.fromCharCode(array[i]);
        }
        return output;
    }
}

class Volume {
    public var header:Dynamic;
    public var data:Dynamic;
    public var segmentation:Bool;

    // ...
}

class Matrix4 {
    // ...
}

class Vector3 {
    // ...
}

class FileLoader {
    // ...
}

class Loader {
    // ...
}