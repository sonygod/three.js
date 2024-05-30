package three.js.loaders;

import three.js.loaders.DataTextureLoader;
import three.js.TextureFilter;

class TGALoader extends DataTextureLoader {
    public function new(manager:LoaderManager) {
        super(manager);
    }

    override function parse(buffer:Array<Int>):Dynamic {
        // TGA constants
        static inline var TGA_TYPE_NO_DATA:Int = 0;
        static inline var TGA_TYPE_INDEXED:Int = 1;
        static inline var TGA_TYPE_RGB:Int = 2;
        static inline var TGA_TYPE_GREY:Int = 3;
        static inline var TGA_TYPE_RLE_INDEXED:Int = 9;
        static inline var TGA_TYPE_RLE_RGB:Int = 10;
        static inline var TGA_TYPE_RLE_GREY:Int = 11;

        static inline var TGA_ORIGIN_MASK:Int = 0x30;
        static inline var TGA_ORIGIN_SHIFT:Int = 0x04;
        static inline var TGA_ORIGIN_BL:Int = 0x00;
        static inline var TGA_ORIGIN_BR:Int = 0x01;
        static inline var TGA_ORIGIN_UL:Int = 0x02;
        static inline var TGA_ORIGIN_UR:Int = 0x03;

        if (buffer.length < 19) throw new Error('THREE.TGALoader: Not enough data to contain header.');

        var offset:Int = 0;
        var content:Array<Int> = buffer;

        var header:{id_length:Int, colormap_type:Int, image_type:Int, colormap_index:Int, colormap_length:Int, colormap_size:Int, origin:Array<Int>, width:Int, height:Int, pixel_size:Int, flags:Int} = {
            id_length: content[offset++],
            colormap_type: content[offset++],
            image_type: content[offset++],
            colormap_index: content[offset++] | content[offset++] << 8,
            colormap_length: content[offset++] | content[offset++] << 8,
            colormap_size: content[offset++],
            origin: [content[offset++] | content[offset++] << 8, content[offset++] | content[offset++] << 8],
            width: content[offset++] | content[offset++] << 8,
            height: content[offset++] | content[offset++] << 8,
            pixel_size: content[offset++],
            flags: content[offset++]
        };

        tgaCheckHeader(header);

        if (header.id_length + offset > buffer.length) throw new Error('THREE.TGALoader: No data.');

        offset += header.id_length;

        var use_rle:Bool = false;
        var use_pal:Bool = false;
        var use_grey:Bool = false;

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

        var imageData:Array<Int> = new Array<Int>(header.width * header.height * 4);
        var result ={
            pixel_data:Array<Int>,
            palettes:Array<Int>
        } = tgaParse(use_rle, use_pal, header, offset, content);
        getTgaRGBA(imageData, header.width, header.height, result.pixel_data, result.palettes);

        return {
            data: imageData,
            width: header.width,
            height: header.height,
            flipY: true,
            generateMipmaps: true,
            minFilter: LinearMipmapLinearFilter
        };
    }

    function tgaCheckHeader(header:{id_length:Int, colormap_type:Int, image_type:Int, colormap_index:Int, colormap_length:Int, colormap_size:Int, origin:Array<Int>, width:Int, height:Int, pixel_size:Int, flags:Int}) {
        switch (header.image_type) {
            case TGA_TYPE_INDEXED:
            case TGA_TYPE_RLE_INDEXED:
                if (header.colormap_length > 256 || header.colormap_size != 24 || header.colormap_type != 1) {
                    throw new Error('THREE.TGALoader: Invalid type colormap data for indexed type.');
                }
                break;
            case TGA_TYPE_RGB:
            case TGA_TYPE_GREY:
            case TGA_TYPE_RLE_RGB:
            case TGA_TYPE_RLE_GREY:
                if (header.colormap_type != 0) {
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

        if (header.pixel_size != 8 && header.pixel_size != 16 && header.pixel_size != 24 && header.pixel_size != 32) {
            throw new Error('THREE.TGALoader: Invalid pixel size ' + header.pixel_size);
        }
    }

    function tgaParse(use_rle:Bool, use_pal:Bool, header:{id_length:Int, colormap_type:Int, image_type:Int, colormap_index:Int, colormap_length:Int, colormap_size:Int, origin:Array<Int>, width:Int, height:Int, pixel_size:Int, flags:Int}, offset:Int, data:Array<Int>):{pixel_data:Array<Int>, palettes:Array<Int>} {
        var pixel_data:Array<Int>;
        var palettes:Array<Int>;

        var pixel_size:Int = header.pixel_size >> 3;
        var pixel_total:Int = header.width * header.height * pixel_size;

        if (use_pal) {
            palettes = data.slice(offset, offset + header.colormap_length * (header.colormap_size >> 3));
        }

        if (use_rle) {
            pixel_data = new Array<Int>(pixel_total);

            var c:Int, count:Int, i:Int, shift:Int = 0;
            var pixels:Array<Int> = new Array<Int>(pixel_size);

            while (shift < pixel_total) {
                c = data[offset++];
                count = (c & 0x7f) + 1;

                if (c & 0x80) {
                    for (i in 0...pixel_size) {
                        pixels[i] = data[offset++];
                    }

                    for (i in 0...count) {
                        pixel_data.set(shift + i * pixel_size, pixels);
                    }

                    shift += pixel_size * count;
                } else {
                    count *= pixel_size;

                    for (i in 0...count) {
                        pixel_data[shift + i] = data[offset++];
                    }

                    shift += count;
                }
            }
        } else {
            pixel_data = data.slice(offset, offset + (use_pal ? header.width * header.height : pixel_total));
        }

        return {
            pixel_data: pixel_data,
            palettes: palettes
        };
    }

    function tgaGetImageData8bits(imageData:Array<Int>, y_start:Int, y_step:Int, y_end:Int, x_start:Int, x_step:Int, x_end:Int, image:Array<Int>, palette:Array<Int>) {
        var color:Int, i:Int = 0, x:Int, y:Int;
        var width:Int = header.width;

        for (y in y_start...y_end) {
            for (x in x_start...x_end) {
                color = image[i++];
                imageData[(x + width * y) * 4 + 3] = 255;
                imageData[(x + width * y) * 4 + 2] = palette[(color * 3) + 0];
                imageData[(x + width * y) * 4 + 1] = palette[(color * 3) + 1];
                imageData[(x + width * y) * 4 + 0] = palette[(color * 3) + 2];
            }
        }

        return imageData;
    }

    function tgaGetImageData16bits(imageData:Array<Int>, y_start:Int, y_step:Int, y_end:Int, x_start:Int, x_step:Int, x_end:Int, image:Array<Int>) {
        var i:Int = 0, x:Int, y:Int;
        var width:Int = header.width;

        for (y in y_start...y_end) {
            for (x in x_start...x_end) {
                var color:Int = image[i++] + (image[i++] << 8);
                imageData[(x + width * y) * 4 + 0] = (color & 0x7c00) >> 7;
                imageData[(x + width * y) * 4 + 1] = (color & 0x03e0) >> 2;
                imageData[(x + width * y) * 4 + 2] = (color & 0x001f) << 3;
                imageData[(x + width * y) * 4 + 3] = (color & 0x8000) != 0 ? 0 : 255;
            }
        }

        return imageData;
    }

    function tgaGetImageData24bits(imageData:Array<Int>, y_start:Int, y_step:Int, y_end:Int, x_start:Int, x_step:Int, x_end:Int, image:Array<Int>) {
        var i:Int = 0, x:Int, y:Int;
        var width:Int = header.width;

        for (y in y_start...y_end) {
            for (x in x_start...x_end) {
                imageData[(x + width * y) * 4 + 3] = 255;
                imageData[(x + width * y) * 4 + 2] = image[i++];
                imageData[(x + width * y) * 4 + 1] = image[i++];
                imageData[(x + width * y) * 4 + 0] = image[i++];
            }
        }

        return imageData;
    }

    function tgaGetImageData32bits(imageData:Array<Int>, y_start:Int, y_step:Int, y_end:Int, x_start:Int, x_step:Int, x_end:Int, image:Array<Int>) {
        var i:Int = 0, x:Int, y:Int;
        var width:Int = header.width;

        for (y in y_start...y_end) {
            for (x in x_start...x_end) {
                imageData[(x + width * y) * 4 + 2] = image[i++];
                imageData[(x + width * y) * 4 + 1] = image[i++];
                imageData[(x + width * y) * 4 + 0] = image[i++];
                imageData[(x + width * y) * 4 + 3] = image[i++];
            }
        }

        return imageData;
    }

    function tgaGetImageDataGrey8bits(imageData:Array<Int>, y_start:Int, y_step:Int, y_end:Int, x_start:Int, x_step:Int, x_end:Int, image:Array<Int>) {
        var color:Int, i:Int = 0, x:Int, y:Int;
        var width:Int = header.width;

        for (y in y_start...y_end) {
            for (x in x_start...x_end) {
                color = image[i++];
                imageData[(x + width * y) * 4 + 0] = color;
                imageData[(x + width * y) * 4 + 1] = color;
                imageData[(x + width * y) * 4 + 2] = color;
                imageData[(x + width * y) * 4 + 3] = 255;
            }
        }

        return imageData;
    }

    function tgaGetImageDataGrey16bits(imageData:Array<Int>, y_start:Int, y_step:Int, y_end:Int, x_start:Int, x_step:Int, x_end:Int, image:Array<Int>) {
        var i:Int = 0, x:Int, y:Int;
        var width:Int = header.width;

        for (y in y_start...y_end) {
            for (x in x_start...x_end) {
                var color:Int = image[i++] + (image[i++] << 8);
                imageData[(x + width * y) * 4 + 0] = (color & 0xff);
                imageData[(x + width * y) * 4 + 1] = (color & 0xff);
                imageData[(x + width * y) * 4 + 2] = (color & 0xff);
                imageData[(x + width * y) * 4 + 3] = (color & 0xff00) != 0 ? 0 : 255;
            }
        }

        return imageData;
    }

    function getTgaRGBA(imageData:Array<Int>, width:Int, height:Int, image:Array<Int>, palette:Array<Int>) {
        var x_start:Int, y_start:Int, x_step:Int, y_step:Int, x_end:Int, y_end:Int;

        switch ((header.flags & TGA_ORIGIN_MASK) >> TGA_ORIGIN_SHIFT) {
            default:
                x_start = 0;
                x_step = 1;
                x_end = width;
                y_start = 0;
                y_step = 1;
                y_end = height;
                break;
            case TGA_ORIGIN_BL:
                x_start = 0;
                x_step = 1;
                x_end = width;
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
            case TGA_ORIGIN_BR:
                x_start = width - 1;
                x_step = -1;
                x_end = -1;
                y_start = height - 1;
                y_step = -1;
                y_end = -1;
                break;
        }

        if (use_grey) {
            switch (header.pixel_size) {
                case 8:
                    tgaGetImageDataGrey8bits(imageData, y_start, y_step, y_end, x_start, x_step, x_end, image);
                    break;
                case 16:
                    tgaGetImageDataGrey16bits(imageData, y_start, y_step, y_end, x_start, x_step, x_end, image);
                    break;
                default:
                    throw new Error('THREE.TGALoader: Format not supported.');
                    break;
            }
        } else {
            switch (header.pixel_size) {
                case 8:
                    tgaGetImageData8bits(imageData, y_start, y_step, y_end, x_start, x_step, x_end, image, palette);
                    break;
                case 16:
                    tgaGetImageData16bits(imageData, y_start, y_step, y_end, x_start, x_step, x_end, image);
                    break;
                case 24:
                    tgaGetImageData24bits(imageData, y_start, y_step, y_end, x_start, x_step, x_end, image);
                    break;
                case 32:
                    tgaGetImageData32bits(imageData, y_start, y_step, y_end, x_start, x_step, x_end, image);
                    break;
                default:
                    throw new Error('THREE.TGALoader: Format not supported.');
                    break;
            }
        }

        return imageData;
    }
}