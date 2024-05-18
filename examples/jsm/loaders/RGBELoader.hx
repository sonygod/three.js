package three.js.examples.jsm.loaders;

import three.DataTextureLoader;
import three.DataUtils;
import three.FloatType;
import three.HalfFloatType;
import three.LinearFilter;
import three.LinearSRGBColorSpace;

class RGBELoader extends DataTextureLoader {
    public function new(manager:Dynamic) {
        super(manager);
        this.type = HalfFloatType;
    }

    // adapted from http://www.graphics.cornell.edu/~bjw/rgbe.html

    public function parse(buffer:ArrayBuffer):Dynamic {
        // default error routine.  change this to change error handling
        var rgbe_read_error = 1;
        var rgbe_write_error = 2;
        var rgbe_format_error = 3;
        var rgbe_memory_error = 4;
        var rgbe_error = function (rgbe_error_code:Int, msg:String) {
            switch (rgbe_error_code) {
                case rgbe_read_error: throw new Error('THREE.RGBELoader: Read Error: ' + (msg || ''));
                case rgbe_write_error: throw new Error('THREE.RGBELoader: Write Error: ' + (msg || ''));
                case rgbe_format_error: throw new Error('THREE.RGBELoader: Bad File Format: ' + (msg || ''));
                default: case rgbe_memory_error: throw new Error('THREE.RGBELoader: Memory Error: ' + (msg || ''));
            }
        };

        // offsets to red, green, and blue components in a data (float) pixel
        // var RGBE_DATA_RED = 0;
        // var RGBE_DATA_GREEN = 1;
        // var RGBE_DATA_BLUE = 2;

        // number of floats per pixel, use 4 since stored in rgba image format
        // var RGBE_DATA_SIZE = 4;

        // flags indicating which fields in an rgbe_header_info are valid
        var RGBE_VALID_PROGRAMTYPE = 1;
        var RGBE_VALID_FORMAT = 2;
        var RGBE_VALID_DIMENSIONS = 4;

        var NEWLINE = '\n';

        var fgets = function (buffer:ArrayBuffer, lineLimit:Int = 1024, consume:Bool = true) {
            var chunkSize = 128;
            lineLimit = lineLimit == null ? 1024 : lineLimit;
            var p = buffer.bytePosition,
                i = -1, len = 0, s = '',
                chunk = '';
            while ((i = chunk.indexOf(NEWLINE)) == -1 && len < lineLimit && p < buffer.byteLength) {
                s += chunk; len += chunk.length;
                p += chunkSize;
                chunk += Std.string(new Uint16Array(buffer.subarray(p, p + chunkSize)));
            }
            if (i != -1) {
                s += chunk.substring(0, i);
                if (consume) buffer.bytePosition = p + i + 1;
                return s;
            }
            return false;
        };

        // minimal header reading.  modify if you want to parse more information
        var RGBE_ReadHeader = function (buffer:ArrayBuffer) {
            // regexes to parse header info fields
            var magic_token_re = ~/^#(?<token>\S+)/;
            var gamma_re = ~/^\s*GAMMA\s*=\s*(?<gamma>[\d\.]+)\s*$/;
            var exposure_re = ~/^\s*EXPOSURE\s*=\s*(?<exposure>[\d\.]+)\s*$/;
            var format_re = ~/^\s*FORMAT=(?<format>\S+)\s*$/;
            var dimensions_re = ~/^\s*-Y\s+(?<height>\d+)\s+\+X\s+(?<width>\d+)\s*$/;

            // RGBE format header struct
            var header = {
                valid: 0, // indicate which fields are valid
                string: '', // the actual header string
                comments: '', // comments found in header
                programtype: 'RGBE', // listed at beginning of file to identify it after "#?"
                format: '', // RGBE format, default 32-bit_rle_rgbe
                gamma: 1.0, // image has already been gamma corrected with given gamma. defaults to 1.0 (no correction)
                exposure: 1.0, // a value of 1.0 in an image corresponds to <exposure> watts/steradian/m^2. defaults to 1.0
                width: 0,
                height: 0 // image dimensions, width/height
            };

            var line, match;

            if (buffer.bytePosition >= buffer.byteLength || !(line = fgets(buffer))) {
                rgbe_error(rgbe_read_error, 'no header found');
            }

            // if you want to require the magic token then uncomment the next line
            if (!(match = line.match(magic_token_re))) {
                rgbe_error(rgbe_format_error, 'bad initial token');
            }

            header.valid |= RGBE_VALID_PROGRAMTYPE;
            header.programtype = match.token;
            header.string += line + '\n';

            while (true) {
                line = fgets(buffer);
                if (line == false) break;
                header.string += line + '\n';

                if (line.charAt(0) == '#') {
                    header.comments += line + '\n';
                    continue; // comment line
                }

                if (match = line.match(gamma_re)) {
                    header.gamma = Std.parseFloat(match.gamma);
                }

                if (match = line.match(exposure_re)) {
                    header.exposure = Std.parseFloat(match.exposure);
                }

                if (match = line.match(format_re)) {
                    header.valid |= RGBE_VALID_FORMAT;
                    header.format = match.format;
                }

                if (match = line.match(dimensions_re)) {
                    header.valid |= RGBE_VALID_DIMENSIONS;
                    header.height = Std.parseInt(match.height);
                    header.width = Std.parseInt(match.width);
                }

                if ((header.valid & RGBE_VALID_FORMAT) && (header.valid & RGBE_VALID_DIMENSIONS)) break;
            }

            if (!(header.valid & RGBE_VALID_FORMAT)) {
                rgbe_error(rgbe_format_error, 'missing format specifier');
            }

            if (!(header.valid & RGBE_VALID_DIMENSIONS)) {
                rgbe_error(rgbe_format_error, 'missing image size specifier');
            }

            return header;
        };

        var RGBE_ReadPixels_RLE = function (buffer:ArrayBuffer, w:Int, h:Int) {
            var scanline_width = w;

            if ((scanline_width < 8 || scanline_width > 0x7fff) || (buffer[0] != 2 || buffer[1] != 2 || (buffer[2] & 0x80) != 0)) {
                // return the flat buffer
                return new Uint8Array(buffer);
            }

            if (scanline_width != ((buffer[2] << 8) | buffer[3])) {
                rgbe_error(rgbe_format_error, 'wrong scanline width');
            }

            var data_rgba = new Uint8Array(4 * w * h);

            if (data_rgba.length == 0) {
                rgbe_error(rgbe_memory_error, 'unable to allocate buffer space');
            }

            var offset = 0, pos = 0;

            var ptr_end = 4 * scanline_width;
            var rgbeStart = new Uint8Array(4);
            var scanline_buffer = new Uint8Array(ptr_end);
            var num_scanlines = h;

            // read in each successive scanline
            while (num_scanlines > 0 && pos < buffer.byteLength) {
                if (pos + 4 > buffer.byteLength) {
                    rgbe_error(rgbe_read_error);
                }

                rgbeStart[0] = buffer[pos++];
                rgbeStart[1] = buffer[pos++];
                rgbeStart[2] = buffer[pos++];
                rgbeStart[3] = buffer[pos++];

                if ((rgbeStart[0] != 2 || rgbeStart[1] != 2) || ((rgbeStart[2] << 8) | rgbeStart[3]) != scanline_width) {
                    rgbe_error(rgbe_format_error, 'bad rgbe scanline format');
                }

                // read each of the four channels for the scanline into the buffer
                // first red, then green, then blue, then exponent
                var ptr = 0, count;

                while (ptr < ptr_end && pos < buffer.byteLength) {
                    count = buffer[pos++];
                    var isEncodedRun = count > 128;
                    if (isEncodedRun) count -= 128;

                    if ((count == 0) || (ptr + count > ptr_end)) {
                        rgbe_error(rgbe_format_error, 'bad scanline data');
                    }

                    if (isEncodedRun) {
                        // a (encoded) run of the same value
                        var byteValue = buffer[pos++];
                        for (i in 0...count) {
                            scanline_buffer[ptr++] = byteValue;
                        }
                        //ptr += count;
                    } else {
                        // a literal-run
                        scanline_buffer.set(buffer.subarray(pos, pos + count), ptr);
                        ptr += count; pos += count;
                    }
                }

                // now convert data from buffer into rgba
                // first red, then green, then blue, then exponent (alpha)
                var l = scanline_width;
                for (i in 0...l) {
                    var off = 0;
                    data_rgba[offset] = scanline_buffer[i + off];
                    off += scanline_width;
                    data_rgba[offset + 1] = scanline_buffer[i + off];
                    off += scanline_width;
                    data_rgba[offset + 2] = scanline_buffer[i + off];
                    off += scanline_width;
                    data_rgba[offset + 3] = scanline_buffer[i + off];
                    offset += 4;
                }

                num_scanlines--;
            }

            return data_rgba;
        };

        var RGBEByteToRGBFloat = function (sourceArray:Array<Int>, sourceOffset:Int, destArray:Array<Float>, destOffset:Int) {
            var e = sourceArray[sourceOffset + 3];
            var scale = Math.pow(2.0, e - 128.0) / 255.0;

            destArray[destOffset + 0] = sourceArray[sourceOffset + 0] * scale;
            destArray[destOffset + 1] = sourceArray[sourceOffset + 1] * scale;
            destArray[destOffset + 2] = sourceArray[sourceOffset + 2] * scale;
            destArray[destOffset + 3] = 1;
        };

        var RGBEByteToRGBHalf = function (sourceArray:Array<Int>, sourceOffset:Int, destArray:Array<Int>, destOffset:Int) {
            var e = sourceArray[sourceOffset + 3];
            var scale = Math.pow(2.0, e - 128.0) / 255.0;

            destArray[destOffset + 0] = DataUtils.toHalfFloat(Math.min(sourceArray[sourceOffset + 0] * scale, 65504));
            destArray[destOffset + 1] = DataUtils.toHalfFloat(Math.min(sourceArray[sourceOffset + 1] * scale, 65504));
            destArray[destOffset + 2] = DataUtils.toHalfFloat(Math.min(sourceArray[sourceOffset + 2] * scale, 65504));
            destArray[destOffset + 3] = DataUtils.toHalfFloat(1);
        };

        var byteArray = new Uint8Array(buffer);
        byteArray.bytePosition = 0;
        var rgbe_header_info = RGBE_ReadHeader(byteArray);

        var w = rgbe_header_info.width;
        var h = rgbe_header_info.height;
        var image_rgba_data = RGBE_ReadPixels_RLE(byteArray.subarray(byteArray.bytePosition), w, h);

        var data, type;
        var numElements;

        switch (this.type) {
            case FloatType:
                numElements = image_rgba_data.length / 4;
                var floatArray = new Float32Array(numElements * 4);

                for (j in 0...numElements) {
                    RGBEByteToRGBFloat(image_rgba_data, j * 4, floatArray, j * 4);
                }

                data = floatArray;
                type = FloatType;
                break;

            case HalfFloatType:
                numElements = image_rgba_data.length / 4;
                var halfArray = new Uint16Array(numElements * 4);

                for (j in 0...numElements) {
                    RGBEByteToRGBHalf(image_rgba_data, j * 4, halfArray, j * 4);
                }

                data = halfArray;
                type = HalfFloatType;
                break;

            default:
                throw new Error('THREE.RGBELoader: Unsupported type: ' + this.type);
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

    public function setDataType(value:Dynamic) {
        this.type = value;
        return this;
    }

    override public function load(url:String, onLoad:(texture:Dynamic, texData:Dynamic)->Void, onProgress:(e:Dynamic)->Void, onError:(e:Dynamic)->Void) {
        super.load(url, function (texture:Dynamic, texData:Dynamic) {
            switch (texture.type) {
                case FloatType:
                case HalfFloatType:
                    texture.colorSpace = LinearSRGBColorSpace;
                    texture.minFilter = LinearFilter;
                    texture.magFilter = LinearFilter;
                    texture.generateMipmaps = false;
                    texture.flipY = true;
                    break;
            }

            if (onLoad != null) onLoad(texture, texData);

        }, onProgress, onError);
    }
}