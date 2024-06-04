import three.DataTextureLoader;
import three.DataUtils;
import three.FloatType;
import three.HalfFloatType;
import three.LinearFilter;
import three.LinearSRGBColorSpace;

// https://github.com/mrdoob/three.js/issues/5552
// http://en.wikipedia.org/wiki/RGBE_image_format

class RGBELoader extends DataTextureLoader {

	public var type:FloatType = HalfFloatType;

	public function new(manager:Dynamic = null) {
		super(manager);
	}

	// adapted from http://www.graphics.cornell.edu/~bjw/rgbe.html

	public function parse(buffer:haxe.io.Bytes):Dynamic {

		// default error routine.  change this to change error handling
		var rgbe_read_error = 1;
		var rgbe_write_error = 2;
		var rgbe_format_error = 3;
		var rgbe_memory_error = 4;
		var rgbe_error = function(rgbe_error_code:Int, msg:String = null) {
			switch(rgbe_error_code) {
				case rgbe_read_error: throw new Error("THREE.RGBELoader: Read Error: " + (msg == null ? "" : msg));
				case rgbe_write_error: throw new Error("THREE.RGBELoader: Write Error: " + (msg == null ? "" : msg));
				case rgbe_format_error: throw new Error("THREE.RGBELoader: Bad File Format: " + (msg == null ? "" : msg));
				default:
				case rgbe_memory_error: throw new Error("THREE.RGBELoader: Memory Error: " + (msg == null ? "" : msg));
			}
		};

		// offsets to red, green, and blue components in a data (float) pixel
		//RGBE_DATA_RED = 0,
		//RGBE_DATA_GREEN = 1,
		//RGBE_DATA_BLUE = 2,

		// number of floats per pixel, use 4 since stored in rgba image format
		//RGBE_DATA_SIZE = 4,

		// flags indicating which fields in an rgbe_header_info are valid
		var RGBE_VALID_PROGRAMTYPE = 1;
		var RGBE_VALID_FORMAT = 2;
		var RGBE_VALID_DIMENSIONS = 4;

		var NEWLINE = "\n";

		var fgets = function(buffer:haxe.io.Bytes, lineLimit:Int = 1024, consume:Bool = true):String {
			var chunkSize = 128;
			var p = buffer.pos;
			var i = -1;
			var len = 0;
			var s = "";
			var chunk = String.fromCharCode.apply(null, new Uint16Array(buffer.subarray(p, p + chunkSize)));
			while((0 > (i = chunk.indexOf(NEWLINE))) && (len < lineLimit) && (p < buffer.length)) {
				s += chunk;
				len += chunk.length;
				p += chunkSize;
				chunk += String.fromCharCode.apply(null, new Uint16Array(buffer.subarray(p, p + chunkSize)));
			}
			if(-1 < i) {
				if(consume == true) buffer.pos += len + i + 1;
				return s + chunk.slice(0, i);
			}
			return false;
		};

		// minimal header reading.  modify if you want to parse more information
		var RGBE_ReadHeader = function(buffer:haxe.io.Bytes):Dynamic {
			// regexes to parse header info fields
			var magic_token_re = /^#\?(\S+)/;
			var gamma_re = /^\s*GAMMA\s*=\s*(\d+(\.\d+)?)\s*$/;
			var exposure_re = /^\s*EXPOSURE\s*=\s*(\d+(\.\d+)?)\s*$/;
			var format_re = /^\s*FORMAT=(\S+)\s*$/;
			var dimensions_re = /^\s*\-Y\s+(\d+)\s+\+X\s+(\d+)\s*$/;

			// RGBE format header struct
			var header = {
				valid: 0, // indicate which fields are valid
				string: "", // the actual header string
				comments: "", // comments found in header
				programtype: "RGBE", // listed at beginning of file to identify it after "#?". defaults to "RGBE"
				format: "", // RGBE format, default 32-bit_rle_rgbe
				gamma: 1.0, // image has already been gamma corrected with given gamma. defaults to 1.0 (no correction)
				exposure: 1.0, // a value of 1.0 in an image corresponds to <exposure> watts/steradian/m^2. defaults to 1.0
				width: 0,
				height: 0 // image dimensions, width/height
			};
			var line:String;
			var match:Array<String>;
			if(buffer.pos >= buffer.length || !((line = fgets(buffer)) != false)) {
				rgbe_error(rgbe_read_error, "no header found");
			}
			// if you want to require the magic token then uncomment the next line
			if(!(match = line.match(magic_token_re))) {
				rgbe_error(rgbe_format_error, "bad initial token");
			}
			header.valid |= RGBE_VALID_PROGRAMTYPE;
			header.programtype = match[1];
			header.string += line + "\n";
			while(true) {
				line = fgets(buffer);
				if(line == false) break;
				header.string += line + "\n";
				if("#" == line.charAt(0)) {
					header.comments += line + "\n";
					continue; // comment line
				}
				if(match = line.match(gamma_re)) {
					header.gamma = Std.parseFloat(match[1]);
				}
				if(match = line.match(exposure_re)) {
					header.exposure = Std.parseFloat(match[1]);
				}
				if(match = line.match(format_re)) {
					header.valid |= RGBE_VALID_FORMAT;
					header.format = match[1]; //'32-bit_rle_rgbe';
				}
				if(match = line.match(dimensions_re)) {
					header.valid |= RGBE_VALID_DIMENSIONS;
					header.height = Std.parseInt(match[1], 10);
					header.width = Std.parseInt(match[2], 10);
				}
				if(((header.valid & RGBE_VALID_FORMAT) != 0) && ((header.valid & RGBE_VALID_DIMENSIONS) != 0)) break;
			}
			if(!((header.valid & RGBE_VALID_FORMAT) != 0)) {
				rgbe_error(rgbe_format_error, "missing format specifier");
			}
			if(!((header.valid & RGBE_VALID_DIMENSIONS) != 0)) {
				rgbe_error(rgbe_format_error, "missing image size specifier");
			}
			return header;
		};

		var RGBE_ReadPixels_RLE = function(buffer:haxe.io.Bytes, w:Int, h:Int):Uint8Array {
			var scanline_width = w;
			if(
				// run length encoding is not allowed so read flat
				((scanline_width < 8) || (scanline_width > 0x7fff)) ||
				// this file is not run length encoded
				((2 != buffer[0]) || (2 != buffer[1]) || ((buffer[2] << 8) | buffer[3]) & 0x80 != 0)
			) {
				// return the flat buffer
				return new Uint8Array(buffer);
			}
			if(scanline_width != ((buffer[2] << 8) | buffer[3])) {
				rgbe_error(rgbe_format_error, "wrong scanline width");
			}
			var data_rgba = new Uint8Array(4 * w * h);
			if(data_rgba.length == 0) {
				rgbe_error(rgbe_memory_error, "unable to allocate buffer space");
			}
			var offset = 0;
			var pos = 0;
			var ptr_end = 4 * scanline_width;
			var rgbeStart = new Uint8Array(4);
			var scanline_buffer = new Uint8Array(ptr_end);
			var num_scanlines = h;
			// read in each successive scanline
			while((num_scanlines > 0) && (pos < buffer.length)) {
				if(pos + 4 > buffer.length) {
					rgbe_error(rgbe_read_error);
				}
				rgbeStart[0] = buffer[pos++];
				rgbeStart[1] = buffer[pos++];
				rgbeStart[2] = buffer[pos++];
				rgbeStart[3] = buffer[pos++];
				if((2 != rgbeStart[0]) || (2 != rgbeStart[1]) || (((rgbeStart[2] << 8) | rgbeStart[3]) != scanline_width)) {
					rgbe_error(rgbe_format_error, "bad rgbe scanline format");
				}
				// read each of the four channels for the scanline into the buffer
				// first red, then green, then blue, then exponent
				var ptr = 0;
				var count:Int;
				while((ptr < ptr_end) && (pos < buffer.length)) {
					count = buffer[pos++];
					var isEncodedRun = count > 128;
					if(isEncodedRun) count -= 128;
					if((0 == count) || (ptr + count > ptr_end)) {
						rgbe_error(rgbe_format_error, "bad scanline data");
					}
					if(isEncodedRun) {
						// a (encoded) run of the same value
						var byteValue = buffer[pos++];
						for(var i = 0; i < count; i++) {
							scanline_buffer[ptr++] = byteValue;
						}
						//ptr += count;
					} else {
						// a literal-run
						scanline_buffer.set(buffer.subarray(pos, pos + count), ptr);
						ptr += count;
						pos += count;
					}
				}
				// now convert data from buffer into rgba
				// first red, then green, then blue, then exponent (alpha)
				var l = scanline_width; //scanline_buffer.byteLength;
				for(var i = 0; i < l; i++) {
					var off = 0;
					data_rgba[offset] = scanline_buffer[i + off];
					off += scanline_width; //1;
					data_rgba[offset + 1] = scanline_buffer[i + off];
					off += scanline_width; //1;
					data_rgba[offset + 2] = scanline_buffer[i + off];
					off += scanline_width; //1;
					data_rgba[offset + 3] = scanline_buffer[i + off];
					offset += 4;
				}
				num_scanlines--;
			}
			return data_rgba;
		};

		var RGBEByteToRGBFloat = function(sourceArray:Uint8Array, sourceOffset:Int, destArray:Float32Array, destOffset:Int) {
			var e = sourceArray[sourceOffset + 3];
			var scale = Math.pow(2.0, e - 128.0) / 255.0;
			destArray[destOffset + 0] = sourceArray[sourceOffset + 0] * scale;
			destArray[destOffset + 1] = sourceArray[sourceOffset + 1] * scale;
			destArray[destOffset + 2] = sourceArray[sourceOffset + 2] * scale;
			destArray[destOffset + 3] = 1;
		};

		var RGBEByteToRGBHalf = function(sourceArray:Uint8Array, sourceOffset:Int, destArray:Uint16Array, destOffset:Int) {
			var e = sourceArray[sourceOffset + 3];
			var scale = Math.pow(2.0, e - 128.0) / 255.0;
			// clamping to 65504, the maximum representable value in float16
			destArray[destOffset + 0] = DataUtils.toHalfFloat(Math.min(sourceArray[sourceOffset + 0] * scale, 65504));
			destArray[destOffset + 1] = DataUtils.toHalfFloat(Math.min(sourceArray[sourceOffset + 1] * scale, 65504));
			destArray[destOffset + 2] = DataUtils.toHalfFloat(Math.min(sourceArray[sourceOffset + 2] * scale, 65504));
			destArray[destOffset + 3] = DataUtils.toHalfFloat(1);
		};

		var byteArray = new Uint8Array(buffer);
		byteArray.pos = 0;
		var rgbe_header_info = RGBE_ReadHeader(byteArray);
		var w = rgbe_header_info.width;
		var h = rgbe_header_info.height;
		var image_rgba_data = RGBE_ReadPixels_RLE(byteArray.subarray(byteArray.pos), w, h);
		var data:Dynamic;
		var type:FloatType;
		var numElements:Int;
		switch(this.type) {
			case FloatType:
				numElements = image_rgba_data.length / 4;
				var floatArray = new Float32Array(numElements * 4);
				for(var j = 0; j < numElements; j++) {
					RGBEByteToRGBFloat(image_rgba_data, j * 4, floatArray, j * 4);
				}
				data = floatArray;
				type = FloatType;
				break;
			case HalfFloatType:
				numElements = image_rgba_data.length / 4;
				var halfArray = new Uint16Array(numElements * 4);
				for(var j = 0; j < numElements; j++) {
					RGBEByteToRGBHalf(image_rgba_data, j * 4, halfArray, j * 4);
				}
				data = halfArray;
				type = HalfFloatType;
				break;
			default:
				throw new Error("THREE.RGBELoader: Unsupported type: " + this.type);
				break;
		}
		return {
			width: w,
			height: h,
			data: data,
			header: rgbe_header_info.string,
			gamma: rgbe_header_info.gamma,
			exposure: rgbe_header_info.exposure,
			type: type
		};
	}

	public function setDataType(value:FloatType):RGBELoader {
		this.type = value;
		return this;
	}

	public function load(url:String, onLoad:Dynamic = null, onProgress:Dynamic = null, onError:Dynamic = null):Dynamic {
		function onLoadCallback(texture:Dynamic, texData:Dynamic) {
			switch(texture.type) {
				case FloatType:
				case HalfFloatType:
					texture.colorSpace = LinearSRGBColorSpace;
					texture.minFilter = LinearFilter;
					texture.magFilter = LinearFilter;
					texture.generateMipmaps = false;
					texture.flipY = true;
					break;
			}
			if(onLoad != null) onLoad(texture, texData);
		}
		return super.load(url, onLoadCallback, onProgress, onError);
	}

}