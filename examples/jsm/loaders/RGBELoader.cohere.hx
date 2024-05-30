import haxe.io.Bytes;
import js.Browser;

class RGBELoader {
    public function new(manager:Dynamic) {
        // ...
    }

    public function parse(buffer:Bytes):Dynamic {
        var rgbe_read_error = 1;
        var rgbe_write_error = 2;
        var rgbe_format_error = 3;
        var rgbe_memory_error = 4;

        function rgbe_error(rgbe_error_code:Int, msg:String) {
            switch (rgbe_error_code) {
                case rgbe_read_error:
                    throw $hxExceptions.ThrowException("Read Error: " + msg);
                    break;
                case rgbe_write_error:
                    throw $hxExceptions.ThrowException("Write Error: " + msg);
                    break;
                case rgbe_format_error:
                    throw $hxExceptions.ThrowException("Bad File Format: " + msg);
                    break;
                default:
                case rgbe_memory_error:
                    throw $hxExceptions.ThrowException("Memory Error: " + msg);
                    break;
            }
        }

        var NEWLINE = "\n";

        function fgets(buffer:Bytes, lineLimit:Int, consume:Bool) -> String {
            var chunkSize = 128;
            lineLimit = (lineLimit != null) ? lineLimit : 1024;
            var p = buffer.pos;
            var i = -1;
            var len = 0;
            var s = "";
            var chunk = haxe.io.StringTools.byteArrayToString(buffer.getData().slice(p, p + chunkSize));

            while ((i = chunk.indexOf(NEWLINE)) == -1 && len < lineLimit && p < buffer.length) {
                s += chunk;
                len += chunk.length;
                p += chunkSize;
                chunk = haxe.io.StringTools.byteArrayToString(buffer.getData().slice(p, p + chunkSize));
            }

            if (i != -1) {
                if (consume != false) {
                    buffer.pos += len + i + 1;
                }
                return s + chunk.substring(0, i);
            } else {
                return null;
            }
        }

        function RGBE_ReadHeader(buffer:Bytes) -> { valid:Int, string:String, comments:String, programtype:String, format:String, gamma:Float, exposure:Float, width:Int, height:Int } {
            var magic_token_re = /^#\?(\S+)/;
            var gamma_re = /^\s*GAMMA\s*=\s*(\d+(\.\d+)?)\s*$/;
            var exposure_re = /^\s*EXPOSURE\s*=\s*(\d+(\.\d+)?)\s*$/;
            var format_re = /^\s*FORMAT=(\S+)\s*$/;
            var dimensions_re = /^\s*\-Y\s+(\d+)\s+\+X\s+(\d+)\s*$/;

            var header = { valid: 0, string: "", comments: "", programtype: "RGBE", format: "", gamma: 1.0, exposure: 1.0, width: 0, height: 0 };

            var line = fgets(buffer);
            var match;

            if (buffer.pos >= buffer.length || line == null) {
                rgbe_error(rgbe_read_error, "no header found");
            }

            if (match = line.match(magic_token_re)) {
                header.valid |= RGBE_VALID_PROGRAMTYPE;
                header.programtype = match[1];
                header.string += line + "\n";
            } else {
                rgbe_error(rgbe_format_error, "bad initial token");
            }

            while (true) {
                line = fgets(buffer);
                if (line == null) {
                    break;
                }
                header.string += line + "\n";

                if (line.charAt(0) == "#") {
                    header.comments += line + "\n";
                    continue;
                }

                if (match = line.match(gamma_re)) {
                    header.gamma = Std.parseFloat(match[1]);
                }

                if (match = line.match(exposure_re)) {
                    header.exposure = Std.parseFloat(match[1]);
                }

                if (match = line.match(format_re)) {
                    header.valid |= RGBE_VALID_FORMAT;
                    header.format = match[1];
                }

                if (match = line.match(dimensions_re)) {
                    header.valid |= RGBE_VALID_DIMENSIONS;
                    header.height = Std.parseInt(match[1]);
                    header.width = Std_parseFloat(match[2]);
                }

                if ((header.valid & RGBE_VALID_FORMAT) != 0 && (header.valid & RGBE_VALID_DIMENSIONS) != 0) {
                    break;
                }
            }

            if ((header.valid & RGBE_VALID_FORMAT) == 0) {
                rgbe_error(rgbe_format_error, "missing format specifier");
            }

            if ((header.valid & RGBE_VALID_DIMENSIONS) == 0) {
                rgbe_error(rgbe_format_error, "missing image size specifier");
            }

            return header;
        }

        function RGBE_ReadPixels_RLE(buffer:Bytes, w:Int, h:Int) -> Bytes {
            var scanline_width = w;

            if (scanline_width < 8 || scanline_width > 0x7fff || buffer.getData()[0] != 2 || buffer.getData()[1] != 2 || (buffer.getData()[2] & 0x80) != 0) {
                return buffer;
            }

            if (scanline_width != ((buffer.getData()[2] << 8) | buffer.getData()[3])) {
                rgbe_error(rgbe_format_error, "wrong scanline width");
            }

            var data_rgba = Bytes.alloc(4 * w * h);
            var offset = 0;
            var pos = 0;
            var ptr_end = 4 * scanline_width;
            var rgbeStart = Bytes.alloc(4);
            var scanline_buffer = Bytes.alloc(ptr_end);
            var num_scanlines = h;

            while (num_scanlines > 0 && pos < buffer.length) {
                if (pos + 4 > buffer.length) {
                    rgbe_error(rgbe_read_error);
                }

                rgbeStart.set(buffer.slice(pos, pos + 4));
                pos += 4;

                if (rgbeStart.getData()[0] != 2 || rgbeStart.getData()[1] != 2 || ((rgbeStart.getData()[2] << 8) | rgbeStart.getData()[3]) != scanline_width) {
                    rgbe_error(rgbe_format_error, "bad rgbe scanline format");
                }

                var ptr = 0;
                var count:Int;

                while (ptr < ptr_end && pos < buffer.length) {
                    count = buffer.getData()[pos++];
                    var isEncodedRun = count > 128;
                    if (isEncodedRun) {
                        count -= 128;
                    }

                    if (count == 0 || ptr + count > ptr_end) {
                        rgbe_error(rgbe_format_error, "bad scanline data");
                    }

                    if (isEncodedRun) {
                        var byteValue = buffer.getData()[pos++];
                        var i = 0;
                        while (i < count) {
                            scanline_buffer.getData()[ptr++] = byteValue;
                            i++;
                        }
                    } else {
                        scanline_buffer.set(buffer.slice(pos, pos + count));
                        pos += count;
                        ptr += count;
                    }
                }

                var l = scanline_width;
                var i = 0;
                while (i < l) {
                    var off = 0;
                    data_rgba.getData()[offset] = scanline_buffer.getData()[i + off];
                    off += scanline_width;
                    data_rgba.getData()[offset + 1] = scanline_buffer.getData()[i + off];
                    off += scanline_width;
                    data_rgba.getData()[offset + 2] = scanline_buffer.getData()[i + off];
                    off += scanline_width;
                    data_rgba.getData()[offset + 3] = scanline_buffer.getData()[i + off];
                    offset += 4;
                    i++;
                }

                num_scanlines--;
            }

            return data_rgba;
        }

        function RGBEByteToRGBFloat(sourceArray:Array<Float>, sourceOffset:Int, destArray:Array<Float>, destOffset:Int):Void {
            var e = sourceArray[sourceOffset + 3];
            var scale = Math.pow(2.0, e - 128.0) / 255.0;

            destArray[destOffset] = sourceArray[sourceOffset] * scale;
            destArray[destOffset + 1] = sourceArray[sourceOffset + 1] * scale;
            destArray[destOffset + 2] = sourceArray[sourceOffset + 2] * scale;
            destArray[destOffset + 3] = 1;
        }

        function RGBEByteToRGBHalf(sourceArray:Array<Float>, sourceOffset:Int, destArray:Array<Float>, destOffset:Int):Void {
            var e = sourceArray[sourceOffset + 3];
            var scale = Math.pow(2.0, e - 128.0) / 255.0;

            destArray[destOffset] = Math.min(sourceArray[sourceOffset] * scale, 65504);
            destArray[destOffset + 1] = Math.min(sourceArray[sourceOffset + 1] * scale, 65504);
            destArray[destOffset + 2] = Math.min(sourceArray[sourceOffset + 2] * scale, 65504);
            destArray[destOffset + 3] = 1;
        }

        var byteArray = buffer;
        byteArray.pos = 0;
        var rgbe_header_info = RGBE_ReadHeader(byteArray);

        var w = rgbe_header_info.width;
        var h = rgbe_header_info.height;
        var image_rgba_data = RGBE_ReadPixels_RLE(byteArray.slice(byteArray.pos), w, h);

        var data:Dynamic;
        var type:Dynamic;
        var numElements:Int;

        switch (this.type) {
            case FloatType:
                numElements = image_rgba_data.length / 4;
                var floatArray = new Array<Float>(numElements * 4);

                var j = 0;
                while (j < numElements) {
                    RGBEByteToRGBFloat(image_rgba_data.getData(), j * 4, floatArray, j * 4);
                    j++;
                }

                data = floatArray;
                type = FloatType;
                break;

            case HalfFloatType:
                numElements = image_rgba_data.length / 4;
                var halfArray = new Array<Float>(numElements * 4);

                var j = 0;
                while (j < numElements) {
                    RGBEByteToRGBHalf(image_rgba_data.getData(), j * 4, halfArray, j * 4);
                    j++;
                }

                data = halfArray;
                type = HalfFloatType;
                break;

            default:
                throw $hxExceptions.ThrowException("Unsupported type: " + this.type);
                break;
        }

        return { width: w, height: h, data: data, header: rgbe_header_info.string, gamma: rgbe_header_info.gamma, exposure: rgbe_header_info.exposure, type: type };
    }

    public function setDataType(value:Dynamic):Dynamic {
        this.type = value;
        return this;
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Dynamic {
        function onLoadCallback(texture:Dynamic, texData:Dynamic) {
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

            if (onLoad != null) {
                onLoad(texture, texData);
            }
        }

        return super.load(url, onLoadCallback, onProgress, onError);
    }
}