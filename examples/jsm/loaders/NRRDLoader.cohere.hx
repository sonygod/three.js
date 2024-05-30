import haxe.io.Bytes;
import js.Browser;

class NRRDLoader {
    public function new(manager:Dynamic) {
        // ...
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.path = scope.path;
        loader.responseType = 'arraybuffer';
        loader.withCredentials = scope.withCredentials;
        loader.load(url, function(data:Bytes) {
            try {
                onLoad(scope.parse(data));
            } catch (e) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function setSegmentation(segmentation:Bool):Void {
        this.segmentation = segmentation;
    }

    public function parse(data:Bytes):Volume {
        var _data = data;
        var _dataPointer = 0;
        var _nativeLittleEndian = haxe.io.Bytes.getByte(haxe.io.Bytes.ofInt16([1]), 0) > 0;
        var _littleEndian = true;
        var headerObject = { };

        function scan(type:String, chunks:Int):Dynamic {
            var _chunkSize = 1;
            var _array_type:Dynamic;

            switch (type) {
                case 'uchar':
                    _array_type = js.Browser.Uint8Array;
                    break;
                case 'schar':
                    _array_type = js.Browser.Int8Array;
                    _chunkSize = 2;
                    break;
                case 'ushort':
                    _array_type = js.Browser.Uint16Array;
                    _chunkSize = 2;
                    break;
                case 'sshort':
                    _array_type = js.Browser.Int16Array;
                    _chunkSize = 2;
                    break;
                case 'uint':
                    _array_type = js.Browser.Uint32Array;
                    _chunkSize = 4;
                    break;
                case 'sint':
                    _array_type = js.Browser.Int32Array;
                    _chunkSize = 4;
                    break;
                case 'float':
                    _array_type = js.Browser.Float32Array;
                    _chunkSize = 4;
                    break;
                case 'complex':
                    _array_type = js.Browser.Float64Array;
                    _chunkSize = 8;
                    break;
                case 'double':
                    _array_type = js.Browser.Float64Array;
                    _chunkSize = 8;
                    break;
            }

            var _bytes = new _array_type(_data.slice(_dataPointer, _dataPointer += chunks * _chunkSize));

            if (_nativeLittleEndian != _littleEndian) {
                _bytes = flipEndianness(_bytes, _chunkSize);
            }

            return _bytes;
        }

        function flipEndianness(array:Dynamic, chunkSize:Int):Dynamic {
            var u8 = new js.Browser.Uint8Array(array.buffer, array.byteOffset, array.byteLength);
            var i = 0, j = 0, k = 0;
            while (i < array.byteLength) {
                j = i + chunkSize - 1;
                k = i;
                while (j > k) {
                    var tmp = u8[k];
                    u8[k] = u8[j];
                    u8[j] = tmp;
                    j--;
                    k++;
                }
                i += chunkSize;
            }
            return array;
        }

        function parseHeader(header:String):Void {
            var data:Dynamic, field:String, fn:Dynamic, i:Int, l:String, m:Dynamic, _i:Int, _len:Int;
            var lines = header.split('\n');
            for (_i = 0, _len = lines.length; _i < _len; _i++) {
                l = lines[_i];
                if (l.match('NRRD\\d+')) {
                    headerObject.isNrrd = true;
                } else if (!(l.match(/^#/)) && (m = l.match(/(.*):(.*)/))) {
                    field = m[1].trim();
                    data = m[2].trim();
                    fn = _fieldFunctions[field];
                    if (fn != null) {
                        fn(headerObject, data);
                    } else {
                        headerObject[field] = data;
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
                    var i = 0;
                    while (i <= 2) {
                        if (!isNaN(headerObject.spacings[i])) {
                            var j = 0;
                            while (j <= 2) {
                                headerObject.vectors[i][j] *= headerObject.spacings[i];
                                j++;
                            }
                        }
                        i++;
                    }
                }
            }
        }

        function parseDataAsText(data:Dynamic, start:Int, end:Int):Dynamic {
            var number = '';
            start = start || 0;
            end = end || data.length;
            var value:Dynamic;
            var lengthOfTheResult = headerObject.sizes.reduce(function(previous:Int, current:Int) {
                return previous * current;
            }, 1);

            var base = 10;
            if (headerObject.encoding == 'hex') {
                base = 16;
            }

            var result = new headerObject.__array(lengthOfTheResult);
            var resultIndex = 0;
            var parsingFunction:Dynamic->Dynamic;
            if (headerObject.__array == js.Browser.Float32Array || headerObject.__array == js.Browser.Float64Array) {
                parsingFunction = Std.parseFloat;
            } else {
                parsingFunction = Std.parseInt;
            }

            var i = start;
            while (i < end) {
                value = data[i];
                if ((value < 9 || value > 13) && value != 32) {
                    number += String.fromCharCode(value);
                } else {
                    if (number != '') {
                        result[resultIndex] = parsingFunction(number, base);
                        resultIndex++;
                    }
                    number = '';
                }
                i++;
            }

            if (number != '') {
                result[resultIndex] = parsingFunction(number, base);
            }

            return result;
        }

        var _bytes = scan('uchar', data.length);
        var _length = _bytes.length;
        var _header:String = null;
        var _data_start = 0;
        var i = 1;
        while (i < _length) {
            if (_bytes[i - 1] == 10 && _bytes[i] == 10) {
                _header = this.parseChars(_bytes, 0, i - 2);
                _data_start = i + 1;
                break;
            }
            i++;
        }

        parseHeader(_header);

        _data = _bytes.subarray(_data_start);
        if (headerObject.encoding.substring(0, 2) == 'gz') {
            _data = fflate.gunzipSync(new js.Browser.Uint8Array(_data));
        } else if (headerObject.encoding == 'ascii' || headerObject.encoding == 'text' || headerObject.encoding == 'txt' || headerObject.encoding == 'hex') {
            _data = parseDataAsText(_data);
        } else if (headerObject.encoding == 'raw') {
            var _copy = new js.Browser.Uint8Array(_data.length);
            var i = 0;
            while (i < _data.length) {
                _copy[i] = _data[i];
                i++;
            }
            _data = _copy;
        }

        _data = _data.buffer;

        var volume = new Volume();
        volume.header = headerObject;
        volume.segmentation = this.segmentation;
        volume.data = new headerObject.__array(_data);
        var min_max = volume.computeMinMax();
        volume.windowLow = min_max[0];
        volume.windowHigh = min_max[1];

        volume.dimensions = [headerObject.sizes[0], headerObject.sizes[1], headerObject.sizes[2]];
        volume.xLength = volume.dimensions[0];
        volume.yLength = volume.dimensions[1];
        volume.zLength = volume.dimensions[2];

        if (headerObject.vectors != null) {
            var xIndex = headerObject.vectors.findIndex(function(vector:Dynamic) {
                return vector[0] != 0;
            });
            var yIndex = headerObject.vectors.findIndex(function(vector:Dynamic) {
                return vector[1] != 0;
            });
            var zIndex = headerObject.vectors.findIndex(function(vector:Dynamic) {
                return vector[2] != 0;
            });

            var axisOrder = [];

            if (xIndex != yIndex && xIndex != zIndex && yIndex != zIndex) {
                axisOrder[xIndex] = 'x';
                axisOrder[yIndex] = 'y';
                axisOrder[zIndex] = 'z';
            } else {
                axisOrder[0] = 'x';
                axisOrder[1] = 'y';
                axisOrder[2] = 'z';
            }

            volume.axisOrder = axisOrder;
        } else {
            volume.axisOrder = ['x', 'y', 'z'];
        }

        var spacingX = new Vector3();
        spacingX.fromArray(headerObject.vectors[0]);
        var spacingY = new Vector3();
        spacingY.fromArray(headerObject.vectors[1]);
        var spacingZ = new Vector3();
        spacingZ.fromArray(headerObject.vectors[2]);
        volume.spacing = [spacingX.length(), spacingY.length(), spacingZ.length()];

        volume.matrix = new Matrix4();

        var transitionMatrix = new Matrix4();

        if (headerObject.space == 'left-posterior-superior') {
            transitionMatrix.set(-1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
        } else if (headerObject.space == 'left-anterior-superior') {
            transitionMatrix.set(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1);
        }

        if (headerObject.vectors == null) {
            volume.matrix.set(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
        } else {
            var v = headerObject.vectors;
            var ijk_to_transition = new Matrix4();
            ijk_to_transition.set(v[0][0], v[1][0], v[2][0], 0, v[0][1], v[1][1], v[2][1], 0, v[0][2], v[1][2], v[2][2], 0, 0, 0, 0, 1);

            var transition_to_ras = new Matrix4();
            transition_to_ras.multiply(ijk_to_transition, transitionMatrix);

            volume.matrix = transition_to_ras;
        }

        volume.inverseMatrix = new Matrix4();
        volume.inverseMatrix.copy(volume.matrix).invert();

        volume.RASDimensions = [
            volume.xLength * volume.spacing[0],
            volume.yLength * volume.spacing[1],
            volume.zLength * volume.spacing[2]
        ];

        if (volume.lowerThreshold == -Infinity) {
            volume.lowerThreshold = volume.windowLow;
        }

        if (volume.upperThreshold == Infinity) {
            volume.upperThreshold = volume.windowHigh;
        }

        return volume;
    }

    function parseChars(array:Dynamic, start:Int, end:Int):String {
        if (start == null) {
            start = 0;
        }

        if (end == null) {
            end = array.length;
        }

        var output = '';
        var i = start;
        while (i < end) {
            output += String.fromCharCode(array[i]);
            i++;
        }

        return output;
    }
}

var _fieldFunctions = {
    type: function(data:String) {
        switch (data) {
            case 'uchar':
            case 'unsigned char':
            case 'uint8':
            case 'uint8_t':
                this.__array = js.Browser.Uint8Array;
                break;
            case 'signed char':
            case 'int8':
            case 'int8_t':
                this.__array = js.Browser.Int8Array;
                break;
            case 'short':
            case 'short int':
            case 'signed short':
            case 'signed short int':
            case 'int16':
            case 'int16_t':
                this.__array = js.Browser.Int16Array;
                break;
            case 'ushort':
            case 'unsigned short':
            case 'unsigned short int':
            case 'uint16':
            case 'uint16_t':
                this.__array = js.Browser.Uint16Array;
                break;
            case 'int':
            case 'signed int':
            case 'int32':
            case 'int32_t':
                this.__array = js.Browser.Int32Array;
                break;
            case 'uint':
            case 'unsigned int':
            case 'uint32':
            case 'uint32_t':
                this.__array = js.Browser.Uint32Array;
                break;
            case 'float':
                this.__array = js.Browser.Float32Array;
                break;
            case 'double':
                this.__array = js.Browser.Float64Array;
                break;
            default:
                throw new Error('Unsupported NRRD data type: ' + data);
        }
        return this.type = data;
    },

    endian: function(data:String) {
        return this.endian = data;
    },

    encoding: function(data:String) {
        return this.encoding = data;
    },

    dimension: function(data:String) {
        return this.dim = Std.parseInt(data);
    },

    sizes: function(data:String) {
        var i:Int;
        return this.sizes = data.split(/\s+/).map(function(i:Int) {
            return Std.parseInt(i);
        });
    },

    space: function(data:String) {
        return this.space = data;
    },

    'space origin': function(data:String) {
        return this.space_origin = data.split('(')[1].split(')')[0].split(',');
    },

    'space directions': function(data:String) {
        var f:Float, v:String;
        var parts = data.match(/\(.*?\)/g);
        return this.vectors = parts.map(function(v:String) {
            return v.slice(1, -1).split(/,/).map(function(f:String) {
                return Std.parseFloat(f);
            });
        });
    },

    spacings: function(data:String) {
        var f:Float;
        var parts = data.split(/\s+/);
        return this.spacings = parts.map(function(f:String) {
            return Std.parseFloat(f);
        });
    }
};