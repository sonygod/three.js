import three.loaders.Loader;
import three.loaders.FileLoader;
import three.math.Vector3;
import three.math.Matrix4;
import misc.Volume;

class NRRDLoader extends Loader {

	public var segmentation:Bool;

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Volume->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
		var scope = this;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(data) {
			try {
				onLoad(scope.parse(data));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	/**
	 *
	 * @param {boolean} segmentation is a option for user to choose
   	 */
	public function setSegmentation(segmentation:Bool) {
		this.segmentation = segmentation;
	}

	public function parse(data:haxe.io.Bytes):Volume {
		// this parser is largely inspired from the XTK NRRD parser : https://github.com/xtk/X

		var _data = data;
		var _dataPointer = 0;

		var _nativeLittleEndian = new Int8Array(new Int16Array([1]).buffer)[0] > 0;
		var _littleEndian = true;
		var headerObject = {};

		var scan = function(type:String, chunks:Int):Array<Int> {
			var _chunkSize = 1;
			var _array_type = Uint8Array;

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

			var _bytes = new _array_type(_data.slice(_dataPointer, _dataPointer += chunks * _chunkSize));

			if (_nativeLittleEndian != _littleEndian) {
				_bytes = flipEndianness(_bytes, _chunkSize);
			}

			return _bytes;
		}

		var flipEndianness = function(array:Array<Int>, chunkSize:Int):Array<Int> {
			var u8 = new Uint8Array(array.buffer, array.byteOffset, array.byteLength);
			for (i in 0...array.byteLength) {
				if (i % chunkSize == 0) {
					for (j in (i + chunkSize - 1)...i) {
						var tmp = u8[j];
						u8[j] = u8[i];
						u8[i] = tmp;
						i++;
					}
				}
			}
			return array;
		}

		var parseHeader = function(header:String) {
			var data, field, fn, i, l, m, _i, _len;
			var lines = header.split(/\r?\n/);
			for (_i in 0...lines.length) {
				l = lines[_i];
				if (l.match(/NRRD\d+/)) {
					headerObject.isNrrd = true;
				} else if (! l.match(/^#/) && (m = l.match(/(.*):(.*)/))) {
					field = m[1].trim();
					data = m[2].trim();
					fn = _fieldFunctions[field];
					if (fn != null) {
						fn.call(headerObject, data);
					} else {
						headerObject[field] = data;
					}
				}
			}

			if (! headerObject.isNrrd) {
				throw new Error('Not an NRRD file');
			}

			if (headerObject.encoding == 'bz2' || headerObject.encoding == 'bzip2') {
				throw new Error('Bzip is not supported');
			}

			if (! headerObject.vectors) {
				headerObject.vectors = [];
				headerObject.vectors.push([1, 0, 0]);
				headerObject.vectors.push([0, 1, 0]);
				headerObject.vectors.push([0, 0, 1]);

				if (headerObject.spacings != null) {
					for (i in 0...3) {
						if (! Math.isNaN(headerObject.spacings[i])) {
							for (j in 0...3) {
								headerObject.vectors[i][j] *= headerObject.spacings[i];
							}
						}
					}
				}
			}
		}

		var parseDataAsText = function(data:Array<Int>, start:Int, end:Int):Array<Float> {
			var number = "";
			start = start == null ? 0 : start;
			end = end == null ? data.length : end;
			var value;
			var lengthOfTheResult = headerObject.sizes.reduce(function(previous:Int, current:Int):Int {
				return previous * current;
			}, 1);

			var base = 10;
			if (headerObject.encoding == 'hex') {
				base = 16;
			}

			var result = new headerObject.__array(lengthOfTheResult);
			var resultIndex = 0;
			var parsingFunction = parseInt;
			if (headerObject.__array == Float32Array || headerObject.__array == Float64Array) {
				parsingFunction = parseFloat;
			}

			for (i in start...end) {
				value = data[i];
				if ((value < 9 || value > 13) && value != 32) {
					number += String.fromCharCode(value);
				} else {
					if (number != "") {
						result[resultIndex] = parsingFunction(number, base);
						resultIndex++;
					}
					number = "";
				}
			}

			if (number != "") {
				result[resultIndex] = parsingFunction(number, base);
				resultIndex++;
			}

			return result;
		}

		var _bytes = scan('uchar', data.length);
		var _length = _bytes.length;
		var _header = null;
		var _data_start = 0;
		for (i in 1..._length) {
			if (_bytes[i - 1] == 10 && _bytes[i] == 10) {
				_header = this.parseChars(_bytes, 0, i - 2);
				_data_start = i + 1;
				break;
			}
		}

		parseHeader(_header);

		_data = _bytes.subarray(_data_start);
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
		var min_max = volume.computeMinMax();
		var min = min_max[0];
		var max = min_max[1];
		volume.windowLow = min;
		volume.windowHigh = max;

		volume.dimensions = [headerObject.sizes[0], headerObject.sizes[1], headerObject.sizes[2]];
		volume.xLength = volume.dimensions[0];
		volume.yLength = volume.dimensions[1];
		volume.zLength = volume.dimensions[2];

		if (headerObject.vectors != null) {
			var xIndex = headerObject.vectors.findIndex(function(vector:Array<Float>):Bool {
				return vector[0] != 0;
			});
			var yIndex = headerObject.vectors.findIndex(function(vector:Array<Float>):Bool {
				return vector[1] != 0;
			});
			var zIndex = headerObject.vectors.findIndex(function(vector:Array<Float>):Bool {
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

		var spacingX = new Vector3().fromArray(headerObject.vectors[0]).length();
		var spacingY = new Vector3().fromArray(headerObject.vectors[1]).length();
		var spacingZ = new Vector3().fromArray(headerObject.vectors[2]).length();
		volume.spacing = [spacingX, spacingY, spacingZ];

		volume.matrix = new Matrix4();

		var transitionMatrix = new Matrix4();

		if (headerObject.space == 'left-posterior-superior') {
			transitionMatrix.set(
				- 1, 0, 0, 0,
				0, - 1, 0, 0,
				0, 0, 1, 0,
				0, 0, 0, 1
			);
		} else if (headerObject.space == 'left-anterior-superior') {
			transitionMatrix.set(
				1, 0, 0, 0,
				0, 1, 0, 0,
				0, 0, - 1, 0,
				0, 0, 0, 1
			);
		}

		if (headerObject.vectors == null) {
			volume.matrix.set(
				1, 0, 0, 0,
				0, 1, 0, 0,
				0, 0, 1, 0,
				0, 0, 0, 1
			);
		} else {
			var v = headerObject.vectors;

			var ijk_to_transition = new Matrix4().set(
				v[0][0], v[1][0], v[2][0], 0,
				v[0][1], v[1][1], v[2][1], 0,
				v[0][2], v[1][2], v[2][2], 0,
				0, 0, 0, 1
			);

			var transition_to_ras = new Matrix4().multiplyMatrices(ijk_to_transition, transitionMatrix);

			volume.matrix = transition_to_ras;
		}

		volume.inverseMatrix = new Matrix4();
		volume.inverseMatrix.copy(volume.matrix).invert();

		volume.RASDimensions = [
			Math.floor(volume.xLength * spacingX),
			Math.floor(volume.yLength * spacingY),
			Math.floor(volume.zLength * spacingZ)
		];

		if (volume.lowerThreshold == -Infinity) {
			volume.lowerThreshold = min;
		}

		if (volume.upperThreshold == Infinity) {
			volume.upperThreshold = max;
		}

		return volume;
	}

	public function parseChars(array:Array<Int>, start:Int, end:Int):String {
		start = start == null ? 0 : start;
		end = end == null ? array.length : end;

		var output = "";
		for (i in start...end) {
			output += String.fromCharCode(array[i]);
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
				this.__array = Uint8Array;
				break;
			case 'signed char':
			case 'int8':
			case 'int8_t':
				this.__array = Int8Array;
				break;
			case 'short':
			case 'short int':
			case 'signed short':
			case 'signed short int':
			case 'int16':
			case 'int16_t':
				this.__array = Int16Array;
				break;
			case 'ushort':
			case 'unsigned short':
			case 'unsigned short int':
			case 'uint16':
			case 'uint16_t':
				this.__array = Uint16Array;
				break;
			case 'int':
			case 'signed int':
			case 'int32':
			case 'int32_t':
				this.__array = Int32Array;
				break;
			case 'uint':
			case 'unsigned int':
			case 'uint32':
			case 'uint32_t':
				this.__array = Uint32Array;
				break;
			case 'float':
				this.__array = Float32Array;
				break;
			case 'double':
				this.__array = Float64Array;
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
		var i;
		return this.sizes = data.split(/\s+/).map(function(i:String):Int {
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
		var f, v;
		var parts = data.match(/\(.*?\)/g);
		return this.vectors = parts.map(function(v:String):Array<Float> {
			return v.slice(1, - 1).split(/,/).map(function(f:String):Float {
				return Std.parseFloat(f);
			});
		});
	},

	spacings: function(data:String) {
		var f;
		var parts = data.split(/\s+/);
		return this.spacings = parts.map(function(f:String):Float {
			return Std.parseFloat(f);
		});
	}
};