import haxe.io.Bytes;

class TGALoader {
    public function new() {
        // ...
    }

    public function parse(buffer: Bytes): Void {
        function tgaCheckHeader(header: TGAHeader) {
            switch (header.image_type) {
                case TGA_TYPE_INDEXED:
                case TGA_TYPE_RLE_INDEXED:
                    if (header.colormap_length > 256 || header.colormap_size != 24 || header.colormap_type != 1) {
                        throw $hxExceptions.throwException("Invalid type colormap data for indexed type.");
                    }
                    break;
                case TGA_TYPE_RGB:
                case TGA_TYPE_GREY:
                case TGA_TYPE_RLE_RGB:
                case TGA_TYPE_RLE_GREY:
                    if (header.colormap_type != 0) {
                        throw $hxExceptions.throwException("Invalid type colormap data for colormap type.");
                    }
                    break;
                case TGA_TYPE_NO_DATA:
                    throw $hxExceptions.throwException("No data.");
                    break;
                default:
                    throw $hxExceptions.throwException("Invalid type " + header.image_type);
            }
            if (header.width <= 0 || header.height <= 0) {
                throw $hxExceptions.throwException("Invalid image size.");
            }
            if (header.pixel_size != 8 && header.pixel_size != 16 && header.pixel_size != 24 && header.pixel_size != 32) {
                throw $hxExceptions.throwException("Invalid pixel size " + header.pixel_size);
            }
        }

        function tgaParse(use_rle: Bool, use_pal: Bool, header: TGAHeader, offset: Int, data: Bytes) {
            var pixel_data: Bytes;
            var palettes: Bytes;
            var pixel_size = header.pixel_size >> 3;
            var pixel_total = header.width * header.height * pixel_size;
            if (use_pal) {
                palettes = data.slice(offset, offset + header.colormap_length * (header.colormap_size >> 3));
                offset += header.colormap_length * (header.colormap_size >> 3);
            }
            if (use_rle) {
                pixel_data = Bytes.alloc(pixel_total);
                var c: Int;
                var count: Int;
                var i: Int;
                var shift: Int = 0;
                var pixels: Bytes = Bytes.alloc(pixel_size);
                while (shift < pixel_total) {
                    c = data.get(offset++);
                    count = (c & 127) + 1;
                    if ((c & 128) != 0) {
                        for (i = 0; i < pixel_size; i++) {
                            pixels.set(i, data.get(offset++));
                        }
                        for (i = 0; i < count; i++) {
                            pixel_data.blit(shift + i * pixel_size, pixels, 0, pixel_size);
                        }
                        shift += pixel_size * count;
                    } else {
                        count *= pixel_size;
                        for (i = 0; i < count; i++) {
                            pixel_data.set(shift + i, data.get(offset++));
                        }
                        shift += count;
                    }
                }
            } else {
                pixel_data = data.slice(offset, offset + (use_pal ? header.width * header.height : pixel_total));
            }
            return { pixel_data: pixel_data, palettes: palettes };
        }

        function tgaGetImageData8bits(imageData: Bytes, y_start: Int, y_step: Int, y_end: Int, x_start: Int, x_step: Int, x_end: Int, image: Bytes, palettes: Bytes) {
            var colormap = palettes;
            var color: Int;
            var i: Int = 0;
            var x: Int;
            var y: Int;
            var width = header.width;
            var _g = y_start;
            while (_g != y_end) {
                var y1 = _g;
                ++_g;
                var _g1 = x_start;
                while (_g1 != x_end) {
                    var x1 = _g1;
                    ++_g1;
                    color = image.get(i++);
                    imageData.set((x1 + width * y1) * 4 + 3, 255);
                    imageData.set((x1 + width * y1) * 4 + 2, colormap.get((color * 3) + 0));
                    imageData.set((x1 + width * y1) * 4 + 1, colormap.get((color * 3) + 1));
                    imageData.set((x1 + width * y1) * 4 + 0, colormap.get((color * 3) + 2));
                }
            }
            return imageData;
        }

        function tgaGetImageData16bits(imageData: Bytes, y_start: Int, y_step: Int, y_end: Int, x_start: Int, x_step: Int, x_end: Int, image: Bytes) {
            var color: Int;
            var i: Int = 0;
            var x: Int;
            var y: Int;
            var width = header.width;
            var _g = y_start;
            while (_g != y_end) {
                var y1 = _g;
                ++_g;
                var _g1 = x_start;
                while (_g1 != x_end) {
                    var x1 = _g1;
                    ++_g1;
                    color = image.get(i + 0) + (image.get(i + 1) << 8);
                    imageData.set((x1 + width * y1) * 4 + 0, (color & 30720) >> 7);
                    imageData.set((x1 + width * y1) * 4 + 1, (color & 12288) >> 2);
                    imageData.set((x1 + width * y1) * 4 + 2, (color & 31) << 3);
                    imageData.set((x1 + width * y1) * 4 + 3, (color & 32768) != 0 ? 0 : 255);
                    i += 2;
                }
            }
            return imageData;
        }

        function tgaGetImageData24bits(imageData: Bytes, y_start: Int, y_step: Int, y_end: Int, x_start: Int, x_step: Int, x_end: Int, image: Bytes) {
            var i: Int = 0;
            var x: Int;
            var y: Int;
            var width = header.width;
            var _g = y_start;
            while (_g != y_end) {
                var y1 = _g;
                ++_g;
                var _g1 = x_start;
                while (_g1 != x_end) {
                    var x1 = _g1;
                    ++_g1;
                    imageData.set((x1 + width * y1) * 4 + 3, 255);
                    imageData.set((x1 + width * y1) * 4 + 2, image.get(i + 0));
                    imageData.set((x1 + width * y1) * 4 + 1, image.get(i + 1));
                    imageData.set((x1 + width * y1) * 4 + 0, image.get(i + 2));
                    i += 3;
                }
            }
            return imageData;
        }

        function tgaGetImageData32bits(imageData: Bytes, y_start: Int, y_step: Int, y_end: Int, x_start: Int, x_step: Int, x_end: Int, image: Bytes) {
            var i: Int = 0;
            var x: Int;
            var y: Int;
            var width = header.width;
            var _g = y_start;
            while (_g != y_end) {
                var y1 = _g;
                ++_g;
                var _g1 = x_start;
                while (_g1 != x_end) {
                    var x1 = _g1;
                    ++_g1;
                    imageData.set((x1 + width * y1) * 4 + 2, image.get(i + 0));
                    imageData.set((x1 + width * y1) * 4 + 1, image.get(i + 1));
                    imageData.set((x1 + width * y1) * 4 + 0, image.get(i + 2));
                    imageData.set((x1 + width * y1) * 4 + 3, image.get(i + 3));
                    i += 4;
                }
            }
            return imageData;
        }

        function tgaGetImageDataGrey8bits(imageData: Bytes, y_start: Int, y_step: Int, y_end: Int, x_start: Int, x_step: Int, x_end: Int, image: Bytes) {
            var color: Int;
            var i: Int = 0;
            var x: Int;
            var y: Int;
            var width = header.width;
            var _g = y_start;
            while (_g != y_end) {
                var y1 = _g;
                ++_g;
                var _g1 = x_start;
                while (_g1 != x_end) {
                    var x1 = _g1;
                    ++_g1;
                    color = image.get(i++);
                    imageData.set((x1 + width * y1) * 4 + 0, color);
                    imageData.set((x1 + width * y1) * 4 + 1, color);
                    imageData.set((x1 + width * y1) * 4 + 2, color);
                    imageData.set((x1 + width * y1) * 4 + 3, 255);
                }
            }
            return imageData;
        }

        function tgaGetImageDataGrey16bits(imageData: Bytes, y_start: Int, y_step: Int, y_end: Int, x_start: Int, x_step: Int, x_end: Int, image: Bytes) {
            var i: Int = 0;
            var x: Int;
            var y: Int;
            var width = header.width;
            var _g = y_start;
            while (_g != y_end) {
                var y1 = _g;
                ++_g;
                var _g1 = x_start;
                while (_g1 != x_end) {
                    var x1 = _g1;
                    ++_g1;
                    imageData.set((x1 + width * y1) * 4 + 0, image.get(i + 0));
                    imageData.set((x1 + width * y1) * 4 + 1, image.get(i + 0));
                    imageData, y: Int, x_step: Int, x_end: Int, image: Bytes) {
                    imageData.set((x1 + width * y1) * 4 + 2, image.get(i + 0));
                    imageData.set((x1 + width * y1) * 4 + 3, image.get(i + 1));
                    i += 2;
                }
            }
            return imageData;
        }

        function getTgaRGBA(data: Bytes, width: Int, height: Int, image: Bytes, palette: Bytes) {
            var x_start: Int;
            var y_start: Int;
            var x_step: Int;
            var y_step: Int;
            var x_end: Int;
            var y_end: Int;
            switch ((header.flags & TGA_ORIGIN_MASK) >> TGA_ORIGIN_SHIFT) {
                case TGA_ORIGIN_BL:
                    x_start = 0;
                    x_step = 1;
                    x_end = width;
                    y_start = height - 1;
                    y_step = -1;
                    y_end = -1;
                    break;
                case TGA_ORIGIN_BR:
                    x_start = width - 1;
                    x_step = -1;
                    x_end = -1;
                    y_start = height - 1;
                    y_step = -1;
                    y_end = -1;
                    break;
                case TGA_ORIGIN_UR:
                    x_start = width - 1;
                    x_step = -1;
                    x_end = -1;
                    y_start = 0;
                    y_step = 1;
                    y_end = height;
                    break;
                default:
                case TGA_ORIGIN_UL:
                    x_start = 0;
                    x_step = 1;
                    x_end = width;
                    y_start = 0;
                    y_step = 1;
                    y_end = height;
                    break;
            }
            if (use_grey) {
                switch (header.pixel_size) {
                    case 8:
                        data = tgaGetImageDataGrey8bits(data, y_start, y_step, y_end, x_start, x_step, x_end, image);
                        break;
                    case 16:
                        data = tgaGetImageDataGrey16bits(data, y_start, y_step, y_end, x_start, x_step, x_end, image);
                        break;
                    default:
                        throw $hxExceptions.throwException("Format not supported.");
                        break;
                }
            } else {
                switch (header.pixel_size) {
                    case 8:
                        data = tgaGetImageData8bits(data, y_start, y_step, y_end, x_start, x_step, x_end, image, palette);
                        break;
                    case 16:
                        data = tgaGetImageData16bits(data, y_start, y_step, y_end, x_start, x_step, x_end, image);
                        break;
                    case 24:
                        data = tgaGetImageData24bits(data, y_start, y_step, y_end, x_start, x_step, x_end, image);
                        break;
                    case 32:
                        data = tgaGetImageData32bits(data, y_start, y_step, y_end, x_start, x_step, x_end, image);
                        break;
                    default:
                        throw $hxExceptions.throwException("Format not supported.");
                        break;
                }
            }
            return data;
        }

        var TGA_TYPE_NO_DATA = 0;
        var TGA_TYPE_INDEXED = 1;
        var TGA_TYPE_RGB = 2;
        var TGA_TYPE_GREY = 3;
        var TGA_TYPE_RLE_INDEXED = 9;
        var TGA_TYPE_RLE_RGB = 10;
        var TGA_TYPE_RLE_GREY = 11;
        var TGA_ORIGIN_MASK = 48;
        var TGA_ORIGIN_SHIFT = 4;
        var TGA_ORIGIN_BL = 0;
        var TGA_ORIGIN_BR = 1;
        var TGA_ORIGIN_UL = 2;
        var TGA_ORIGIN_UR = 3;
        if (buffer.length < 19) {
            throw $hxExceptions.throwException("Not enough data to contain header.");
        }
        var offset: Int = 0;
        var content = buffer;
        var header = {
            id_length: content.get(offset++),
            colormap_type: content.get(offset++),
            image_type: content.get(offset++),
            colormap_index: content.get(offset++) | content.get(offset++) << 8,
            colormap_length: content.get(offset++) | content.get(offset++) << 8,
            colormap_size: content.get(offset++),
            origin: [content.get(offset++) | content.get(offset++) << 8, content.get(offset++) | content.get(offset++) << 8],
            width: content.get(offset++) | content.get(offset++) << 8,
            height: content.get(offset++) | content.get(offset++) << 8,
            pixel_size: content.get(offset++),
            flags: content.get(offset++)
        };
        tgaCheckHeader(header);
        if (header.id_length + offset > buffer.length) {
            throw $hxExceptions.throwException("No data.");
        }
        offset += header.id_length;
        var use_rle: Bool;
        var use_pal: Bool;
        var use_grey: Bool;
        switch (header.image_type) {
            case TGA_TYPE_RLE_INDEXED:
                use_rle = true;
                use_pal = true;
                break;
            case TGA_TYPE_INDEXED:
                use_pal = true;
                break;
            case TGA_TYPE_RLE_RGB:
                use_rle = true;
                break;
            case TGA_TYPE_RGB:
                break;
            case TGA_TYPE_RLE_GREY:
                use_rle = true;
                use_grey = true;
                break;
            case T
case TGA_TYPE_GREY:
                use_grey = true;
                break;
        }
        var imageData = Bytes.alloc(header.width * header.height * 4);
        var result = tgaParse(use_rle, use_pal, header, offset, content);
        imageData = getTgaRGBA(imageData, header.width, header.height, result.pixel_data, result.palettes);
        return {
            data: imageData,
            width: header.width,
            height: header.height,
            flipY: true,
            generateMipmaps: true,
            minFilter: LinearMipmapLinearFilter
        };
    }
}

type TGAHeader = {
    id_length: Int,
    colormap_type: Int,
    image_type: Int,
    colormap_index: Int,
    colormap_length: Int,
    colormap_size: Int,
    origin: Array<Int>,
    width: Int,
    height: Int,
    pixel_size: Int,
    flags: Int
};