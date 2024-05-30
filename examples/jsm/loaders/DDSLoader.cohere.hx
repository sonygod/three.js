import haxe.io.Bytes;

class DDSLoader {
    public function new() {
        // ...
    }

    public function parse(buffer: Bytes, loadMipmaps: Bool): DDS {
        var dds = { mipmaps: [], width: 0, height: 0, format: null, mipmapCount: 1 };

        // Adapted from @toji's DDS utils
        // https://github.com/toji/webgl-texture-utils/blob/master/texture-util/dds.js

        // All values and structures referenced from:
        // http://msdn.microsoft.com/en-us/library/bb943991.aspx/

        var DDS_MAGIC = 0x20534444;

        var DDSD_CAPS = 0x1;
        var DDSD_HEIGHT = 0x2;
        var DDSD_WIDTH = 0x4;
        var DDSD_PITCH = 0x8;
        var DDSD_PIXELFORMAT = 0x1000;
        var DDSD_MIPMAPCOUNT = 0x20000;
        var DDSD_LINEARSIZE = 0x80000;
        var DDSD_DEPTH = 0x800000;

        var DDSCAPS_COMPLEX = 0x8;
        var DDSCAPS_MIPMAP = 0x400000;
        var DDSCAPS_TEXTURE = 0x1000;

        var DDSCAPS2_CUBEMAP = 0x200;
        var DDSCAPS2_CUBEMAP_POSITIVEX = 0x400;
        var DDSCAPS2_CUBEMAP_NEGATIVEX = 0x800;
        var DDSCAPS2_CUBEMAP_POSITIVEY = 0x1000;
        var DDSCAPS2_CUBEMAP_NEGATIVEY = 0x2000;
        var DDSCAPS2_CUBEMAP_POSITIVEZ = 0x4000;
        var DDSCAPS2_CUBEMAP_NEGATIVEZ = 0x8000;
        var DDSCAPS2_VOLUME = 0x200000;

        var DDPF_ALPHAPIXELS = 0x1;
        var DDPF_ALPHA = 0x2;
        var DDPF_FOURCC = 0x4;
        var DDPF_RGB = 0x40;
        var DDPF_YUV = 0x200;
        var DDPF_LUMINANCE = 0x20000;

        var DXGI_FORMAT_BC6H_UF16 = 95;
        var DXGI_FORMAT_BC6H_SF16 = 96;

        function fourCCToInt32(value: String): Int {
            var result = 0;
            for (i in 0...value.length) {
                result = (result << 8) | value.charCodeAt(i);
            }
            return result;
        }

        function int32ToFourCC(value: Int): String {
            var chars = [];
            for (i in 0...4) {
                chars.push(String.fromCharCode(value & 0xff));
                value = value >> 8;
            }
            return chars.join('');
        }

        function loadARGBMip(buffer: Bytes, dataOffset: Int, width: Int, height: Int): Bytes {
            var dataLength = width * height * 4;
            var srcBuffer = buffer.getBytes(dataOffset, dataLength);
            var byteArray = Bytes.alloc(dataLength);
            var dst = 0;
            var src = 0;
            for (y in 0...height) {
                for (x in 0...width) {
                    var b = srcBuffer.get(src); src++;
                    var g = srcBuffer.get(src); src++;
                    var r = srcBuffer.get(src); src++;
                    var a = srcBuffer.get(src); src++;
                    byteArray.set(dst, r); dst++; //r
                    byteArray.set(dst, g); dst++; //g
                    byteArray.set(dst, b); dst++; //b
                    byteArray.set(dst, a); dst++; //a
                }
            }
            return byteArray;
        }

        var FOURCC_DXT1 = fourCCToInt32('DXT1');
        var FOURCC_DXT3 = fourCCToInt32('DXT3');
        var FOURCC_DXT5 = fourCCToInt32('DXT5');
        var FOURCC_ETC1 = fourCCToInt32('ETC1');
        var FOURCC_DX10 = fourCCToInt32('DX10');

        var headerLengthInt = 31; // The header length in 32 bit ints
        var extendedHeaderLengthInt = 5; // The extended header length in 32 bit ints

        // Offsets into the header array

        var off_magic = 0;

        var off_size = 1;
        var off_flags = 2;
        var off_height = 3;
        var off_width = 4;

        var off_mipmapCount = 7;

        var off_pfFlags = 20;
        var off_pfFourCC = 21;
        var off_RGBBitCount = 22;
        var off_RBitMask = 23;
        var off_GBitMask = 24;
        var off_BBitMask = 25;
        var off_ABitMask = 26;

        var off_caps = 27;
        var off_caps2 = 28;
        var off_caps3 = 29;
        var off_caps4 = 30;

        // If fourCC = DX10, the extended header starts after 32
        var off_dxgiFormat = 0;

        // Parse header

        var header = buffer.getInt32Array();

        if (header[off_magic] != DDS_MAGIC) {
            trace('Invalid magic number in DDS header.');
            return dds;
        }

        var blockBytes: Int;

        var fourCC = header[off_pfFourCC];

        var isRGBAUncompressed = false;

        var dataOffset = header[off_size] + 4;

        switch (fourCC) {
            case FOURCC_DXT1:
                blockBytes = 8;
                dds.format = RGB_S3TC_DXT1_Format;
                break;
            case FOURCC_DXT3:
                blockBytes = 16;
                dds.format = RGBA_S3TC_DXT3_Format;
                break;
            case FOURCC_DXT5:
                blockBytes = 16;
                dds.format = RGBA_S3TC_DXT5_Format;
                break;
            case FOURCC_ETC1:
                blockBytes = 8;
                dds.format = RGB_ETC1_Format;
                break;
            case FOURCC_DX10:
                dataOffset += extendedHeaderLengthInt * 4;
                var extendedHeader = buffer.getInt32Array(headerLengthInt * 4 + 1, extendedHeaderLengthInt);
                var dxgiFormat = extendedHeader[off_dxgiFormat];
                switch (dxgiFormat) {
                    case DXGI_FORMAT_BC6H_SF16:
                        blockBytes = 16;
                        dds.format = RGB_BPTC_SIGNED_Format;
                        break;
                    case DXGI_FORMAT_BC6H_UF16:
                        blockBytes = 16;
                        dds.format = RGB_BPTC_UNSIGNED_Format;
                        break;
                    default:
                        trace('Unsupported DXGI_FORMAT code ' + dxgiFormat);
                        return dds;
                }
                break;
            default:
                if (header[off_RGBBitCount] == 32 &&
                    header[off_RBitMask] & 0xff0000 &&
                    header[off_GBitMask] & 0xff00 &&
                    header[off_BBitMask] & 0xff &&
                    header[off_ABitMask] & 0xff000000) {

                    isRGBAUncompressed = true;
                    blockBytes = 64;
                    dds.format = RGBAFormat;
                } else {
                    trace('Unsupported FourCC code ' + int32ToFourCC(fourCC));
                    return dds;
                }
        }

        dds.mipmapCount = 1;

        if (header[off_flags] & DDSD_MIPMAPCOUNT && loadMipmaps != false) {
            dds.mipmapCount = Math.max(1, header[off_mipmapCount]);
        }

        var caps2 = header[off_caps2];
        dds.isCubemap = (caps2 & DDSCAPS2_CUBEMAP) != 0;
        if (dds.isCubemap &&
            !(caps2 & DDSCAPS2_CUBEMAP_POSITIVEX) ||
            !(caps2 & DDSCAPS2_CUBEMAP_NEGATIVEX) ||
            !(caps2 & DDSCAPS2_CUBEMAP_POSITIVEY) ||
            !(caps2 & DDSCAPS2_CUBEMAP_NEGATIVEY) ||
            !(caps2 & DDSCAPS2_CUBEMAP_POSITIVEZ) ||
            !(caps2 & DDSCAPS2_CUBEMAP_NEGATIVEZ)) {

            trace('Incomplete cubemap faces');
            return dds;
        }

        dds.width = header[off_width];
        dds.height = header[off_height];

        // Extract mipmaps buffers

        var faces = dds.isCubemap ? 6 : 1;

        for (face in 0...faces) {
            var width = dds.width;
            var height = dds.height;

            for (i in 0...dds.mipmapCount) {
                var byteArray: Bytes;
                var dataLength: Int;

                if (isRGBAUncompressed) {
                    byteArray = loadARGBMip(buffer, dataOffset, width, height);
                    dataLength = byteArray.length;
                } else {
                    dataLength = Math.max(4, width) / 4 * Math.max(4, height) / 4 * blockBytes;
                    byteArray = buffer.getBytes(dataOffset, dataLength);
                }

                var mipmap = { 'data': byteArray, 'width': width, 'height': height };
                dds.mipmaps.push(mipmap);

                dataOffset += dataLength;

                width = Math.max(width >> 1, 1);
                height = Math.max(height >> 1, 1);
            }
        }

        return dds;
    }
}

typedef DDS = {
    mipmaps: Array<Mipmap>,
    width: Int,
    height: Int,
    format: Format,
    mipmapCount: Int,
    isCubemap: Bool
}

typedef Mipmap = {
    data: Bytes,
    width: Int,
    height: Int
}

typedef Format = AbstractFormat | RGBAFormat | RGB_S3TC_DXT1_Format | RGBA_S3TC_DXT3_Format | RGBA_S3TC_DXT5_Format | RGB_ETC1_Format | RGB_BPTC_SIGNED_Format | RGB_BPTC_UNSIGNED_Format;

typedef AbstractFormat = {
    __abstract__: Format
}

typedef RGBAFormat = {
    __typename__: 'RGBAFormat'
}

typedef RGB_S3TC_DXT1_Format = {
    __typename__: 'RGB_S3TC_DXT1_Format'
}

typedef RGBA_S3TC_DXT3_Format = {
    __typename__: 'RGBA_S3TC_DXT3_Format'
}

typedef RGBA_S3TC_DXT5_Format = {
    __typename__: 'RGBA_S3TC_DXT5_Format'
}

typedef RGB_ETC1_Format = {
    __typename__: 'RGB_ETC1_Format'
}

typedef RGB_BPTC_SIGNED_Format = {
    __typename__: 'RGB_BPTC_SIGNED_Format'
}

typedef RGB_BPTC_UNSIGNED_Format = {
    __typename__: 'RGB_BPTC_UNSIGNED_Format'
}