import three.DataTextureLoader;
import three.LinearMipmapLinearFilter;

class TGALoader extends DataTextureLoader {
    public function new(manager:LoadingManager) {
        super(manager);
    }

    public function parse(buffer:ArrayBuffer):Dynamic {
        // TGA constants
        var TGA_TYPE_NO_DATA = 0;
        var TGA_TYPE_INDEXED = 1;
        var TGA_TYPE_RGB = 2;
        var TGA_TYPE_GREY = 3;
        var TGA_TYPE_RLE_INDEXED = 9;
        var TGA_TYPE_RLE_RGB = 10;
        var TGA_TYPE_RLE_GREY = 11;
        var TGA_ORIGIN_MASK = 0x30;
        var TGA_ORIGIN_SHIFT = 0x04;
        var TGA_ORIGIN_BL = 0x00;
        var TGA_ORIGIN_BR = 0x01;
        var TGA_ORIGIN_UL = 0x02;
        var TGA_ORIGIN_UR = 0x03;

        if (buffer.length < 19) throw new Error('THREE.TGALoader: Not enough data to contain header.');

        var offset = 0;
        var content = new Uint8Array(buffer);
        var header = {
            id_length: content[offset++],
            colormap_type: content[offset++],
            image_type: content[offset++],
            colormap_index: content[offset++] | content[offset++] << 8,
            colormap_length: content[offset++] | content[offset++] << 8,
            colormap_size: content[offset++],
            origin: [
                content[offset++] | content[offset++] << 8,
                content[offset++] | content[offset++] << 8
            ],
            width: content[offset++] | content[offset++] << 8,
            height: content[offset++] | content[offset++] << 8,
            pixel_size: content[offset++],
            flags: content[offset++]
        };

        tgaCheckHeader(header);

        if (header.id_length + offset > buffer.length) {
            throw new Error('THREE.TGALoader: No data.');
        }

        offset += header.id_length;

        var use_rle = false;
        var use_pal = false;
        var use_grey = false;

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
            case TGA_TYPE_GREY:
                use_grey = true;
                break;
        }

        var imageData = new Uint8Array(header.width * header.height * 4);
        var result = tgaParse(use_rle, use_pal, header, offset, content);
        getTgaRGBA(imageData, header.width, header.height, result.pixel_data, result.palettes);

        return {
            data: imageData,
            width: header.width,
            height: header.height,
            flipY: true,
            generateMipmaps: true,
            minFilter: LinearMipmapLinearFilter,
        };
    }

    private function tgaCheckHeader(header:Dynamic) {
        switch (header.image_type) {
            case TGA_TYPE_INDEXED:
            case TGA_TYPE_RLE_INDEXED:
                if (header.colormap_length > 256 || header.colormap_size !== 24 || header.colormap_type !== 1) {
                    throw new Error('THREE.TGALoader: Invalid type colormap data for indexed type.');
                }
                break;
            case TGA_TYPE_RGB:
            case TGA_TYPE_GREY:
            case TGA_TYPE_RLE_RGB:
            case TGA_TYPE_RLE_GREY:
                if (header.colormap_type) {
                    throw new Error('THREE.TGALoader: Invalid type colormap data for colormap type.');
                }
                break;
            case TGA_TYPE_NO_DATA:
                throw new Error('THREE.TGALoader: No data.');
            default:
                throw new Error('THREE.TGALoader: Invalid type ' + header.image_type);
        }

        if (header.width <= 0 || header.height <= 0) {
            throw new Error('THREE.TGALoader: Invalid image size.');
        }

        if (header.pixel_size !== 8 && header.pixel_size !== 16 && header.pixel_size !== 24 && header.pixel_size !== 32) {
            throw new Error('THREE.TGALoader: Invalid pixel size ' + header.pixel_size);
        }
    }

    private function tgaParse(use_rle:Bool, use_pal:Bool, header:Dynamic, offset:Int, data:Uint8Array):Dynamic {
        var pixel_data:Uint8Array;
        var palettes:Uint8Array;
        var pixel_size = header.pixel_size >> 3;
        var pixel_total = header.width * header.height * pixel_size;

        if (use_pal) {
            palettes = data.subarray(offset, offset += header.colormap_length * (header.colormap_size >> 3));
        }

        if (use_rle) {
            pixel_data = new Uint8Array(pixel_total);
            var c:Int;
            var count:Int;
            var i:Int;
            var shift = 0;
            var pixels = new Uint8Array(pixel_size);

            while (shift < pixel_total) {
                c = data[offset++];
                count = (c & 0x7f) + 1;

                if (c & 0x80) {
                    for (i = 0; i < pixel_size; ++i) {
                        pixels[i] = data[offset++];
                    }

                    for (i = 0; i < count; ++i) {
                        pixel_data.set(pixels, shift + i * pixel_size);
                    }

                    shift += pixel_size * count;
                } else {
                    count *= pixel_size;

                    for (i = 0; i < count; ++i) {
                        pixel_data[shift + i] = data[offset++];
                    }

                    shift += count;
                }
            }
        } else {
            pixel_data = data.subarray(offset, offset += (use_pal ? header.width * header.height : pixel_total));
        }

        return {
            pixel_data: pixel_data,
            palettes: palettes
        };
    }

    // The rest of the functions (tgaGetImageData8bits, tgaGetImageData16bits, etc.)
    // and the getTgaRGBA function can be added similarly.
}