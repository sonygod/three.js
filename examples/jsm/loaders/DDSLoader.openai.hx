package three.js.examples.jsm.loaders;

import three.js.CompressedTextureLoader;
import three.js.RGBAFormat;
import three.js.RGBA_S3TC_DXT3_Format;
import three.js.RGBA_S3TC_DXT5_Format;
import three.js.RGB_ETC1_Format;
import three.js.RGB_S3TC_DXT1_Format;
import three.js.RGB_BPTC_SIGNED_Format;
import three.js.RGB_BPTC_UNSIGNED_Format;

class DDSLoader extends CompressedTextureLoader {
    public function new(manager:Dynamic) {
        super(manager);
    }

    public function parse(buffer:ByteArray, loadMipmaps:Bool = true):.dds.DDS {
        var dds:Dds = {
            mipmaps: [],
            width: 0,
            height: 0,
            format: null,
            mipmapCount: 1
        };

        // Adapted from @toji's DDS utils
        // https://github.com/toji/webgl-texture-utils/blob/master/texture-util/dds.js

        // All values and structures referenced from:
        // http://msdn.microsoft.com/en-us/library/bb943991.aspx/

        const DDS_MAGIC:Int = 0x20534444;

        // const DDSD_CAPS:Int = 0x1;
        // const DDSD_HEIGHT:Int = 0x2;
        // const DDSD_WIDTH:Int = 0x4;
        // const DDSD_PITCH:Int = 0x8;
        // const DDSD_PIXELFORMAT:Int = 0x1000;
        const DDSD_MIPMAPCOUNT:Int = 0x20000;
        // const DDSD_LINEARSIZE:Int = 0x80000;
        // const DDSD_DEPTH:Int = 0x800000;

        // const DDSCAPS_COMPLEX:Int = 0x8;
        // const DDSCAPS_MIPMAP:Int = 0x400000;
        // const DDSCAPS_TEXTURE:Int = 0x1000;

        const DDSCAPS2_CUBEMAP:Int = 0x200;
        const DDSCAPS2_CUBEMAP_POSITIVEX:Int = 0x400;
        const DDSCAPS2_CUBEMAP_NEGATIVEX:Int = 0x800;
        const DDSCAPS2_CUBEMAP_POSITIVEY:Int = 0x1000;
        const DDSCAPS2_CUBEMAP_NEGATIVEY:Int = 0x2000;
        const DDSCAPS2_CUBEMAP_POSITIVEZ:Int = 0x4000;
        const DDSCAPS2_CUBEMAP_NEGATIVEZ:Int = 0x8000;
        // const DDSCAPS2_VOLUME:Int = 0x200000;

        // const DDPF_ALPHAPIXELS:Int = 0x1;
        // const DDPF_ALPHA:Int = 0x2;
        // const DDPF_FOURCC:Int = 0x4;
        // const DDPF_RGB:Int = 0x40;
        // const DDPF_YUV:Int = 0x200;
        // const DDPF_LUMINANCE:Int = 0x20000;

        const DXGI_FORMAT_BC6H_UF16:Int = 95;
        const DXGI_FORMAT_BC6H_SF16:Int = 96;

        function fourCCToInt32(value:String):Int {
            return value.charCodeAt(0) + (value.charCodeAt(1) << 8) + (value.charCodeAt(2) << 16) + (value.charCodeAt(3) << 24);
        }

        function int32ToFourCC(value:Int):String {
            return String.fromCharCode(value & 0xff, (value >> 8) & 0xff, (value >> 16) & 0xff, (value >> 24) & 0xff);
        }

        function loadARGBMip(buffer:ByteArray, dataOffset:Int, width:Int, height:Int):ByteArray {
            var dataLength:Int = width * height * 4;
            var srcBuffer:ByteArray = new ByteArray(buffer, dataOffset, dataLength);
            var byteArray:ByteArray = new ByteArray(dataLength);
            var dst:Int = 0;
            var src:Int = 0;
            for (y in 0...height) {
                for (x in 0...width) {
                    var b:Int = srcBuffer[src++];
                    var g:Int = srcBuffer[src++];
                    var r:Int = srcBuffer[src++];
                    var a:Int = srcBuffer[src++];
                    byteArray[dst++] = r; // r
                    byteArray[dst++] = g; // g
                    byteArray[dst++] = b; // b
                    byteArray[dst++] = a; // a
                }
            }
            return byteArray;
        }

        const FOURCC_DXT1:Int = fourCCToInt32('DXT1');
        const FOURCC_DXT3:Int = fourCCToInt32('DXT3');
        const FOURCC_DXT5:Int = fourCCToInt32('DXT5');
        const FOURCC_ETC1:Int = fourCCToInt32('ETC1');
        const FOURCC_DX10:Int = fourCCToInt32('DX10');

        const headerLengthInt:Int = 31; // The header length in 32 bit ints
        const extendedHeaderLengthInt:Int = 5; // The extended header length in 32 bit ints

        // Offsets into the header array

        const off_magic:Int = 0;

        const off_size:Int = 1;
        const off_flags:Int = 2;
        const off_height:Int = 3;
        const off_width:Int = 4;

        const off_mipmapCount:Int = 7;

        // const off_pfFlags:Int = 20;
        const off_pfFourCC:Int = 21;
        const off_RGBBitCount:Int = 22;
        const off_RBitMask:Int = 23;
        const off_GBitMask:Int = 24;
        const off_BBitMask:Int = 25;
        const off_ABitMask:Int = 26;

        // const off_caps:Int = 27;
        const off_caps2:Int = 28;
        // const off_caps3:Int = 29;
        // const off_caps4:Int = 30;

        // If fourCC = DX10, the extended header starts after 32
        const off_dxgiFormat:Int = 0;

        // Parse header

        var header:Int32Array = new Int32Array(buffer, 0, headerLengthInt);

        if (header[off_magic] != DDS_MAGIC) {
            trace('THREE.DDSLoader.parse: Invalid magic number in DDS header.');
            return dds;
        }

        var blockBytes:Int;

        var fourCC:Int = header[off_pfFourCC];

        var isRGBAUncompressed:Bool = false;

        var dataOffset:Int = header[off_size] + 4;

        switch (fourCC) {
            case FOURCC_DXT1:
                blockBytes = 8;
                dds.format = RGBA_S3TC_DXT1_Format;
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
                var extendedHeader:Int32Array = new Int32Array(buffer, (headerLengthInt + 1) * 4, extendedHeaderLengthInt);
                var dxgiFormat:Int = extendedHeader[off_dxgiFormat];
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
                        trace('THREE.DDSLoader.parse: Unsupported DXGI_FORMAT code ' + dxgiFormat);
                        return dds;
                }

                break;

            default:
                if (header[off_RGBBitCount] == 32
                    && header[off_RBitMask] & 0xff0000
                    && header[off_GBitMask] & 0xff00
                    && header[off_BBitMask] & 0xff
                    && header[off_ABitMask] & 0xff000000) {

                    isRGBAUncompressed = true;
                    blockBytes = 64;
                    dds.format = RGBAFormat;

                } else {
                    trace('THREE.DDSLoader.parse: Unsupported FourCC code ' + int32ToFourCC(fourCC));
                    return dds;
                }
        }

        dds.mipmapCount = 1;

        if (header[off_flags] & DDSD_MIPMAPCOUNT && loadMipmaps) {
            dds.mipmapCount = Math.max(1, header[off_mipmapCount]);
        }

        var caps2:Int = header[off_caps2];
        dds.isCubemap = caps2 & DDSCAPS2_CUBEMAP ? true : false;
        if (dds.isCubemap && (
            ! (caps2 & DDSCAPS2_CUBEMAP_POSITIVEX) ||
            ! (caps2 & DDSCAPS2_CUBEMAP_NEGATIVEX) ||
            ! (caps2 & DDSCAPS2_CUBEMAP_POSITIVEY) ||
            ! (caps2 & DDSCAPS2_CUBEMAP_NEGATIVEY) ||
            ! (caps2 & DDSCAPS2_CUBEMAP_POSITIVEZ) ||
            ! (caps2 & DDSCAPS2_CUBEMAP_NEGATIVEZ)
        ) ) {
            trace('THREE.DDSLoader.parse: Incomplete cubemap faces');
            return dds;
        }

        dds.width = header[off_width];
        dds.height = header[off_height];

        // Extract mipmaps buffers

        var faces:Int = dds.isCubemap ? 6 : 1;

        for (face in 0...faces) {
            var width:Int = dds.width;
            var height:Int = dds.height;

            for (i in 0...dds.mipmapCount) {
                var byteArray:ByteArray, dataLength:Int;

                if (isRGBAUncompressed) {
                    byteArray = loadARGBMip(buffer, dataOffset, width, height);
                    dataLength = byteArray.length;

                } else {
                    dataLength = Math.max(4, width) / 4 * Math.max(4, height) / 4 * blockBytes;
                    byteArray = new ByteArray(buffer, dataOffset, dataLength);
                }

                var mipmap:DdsMipmap = {
                    data: byteArray,
                    width: width,
                    height: height
                };
                dds.mipmaps.push(mipmap);

                dataOffset += dataLength;

                width = Math.max(width >> 1, 1);
                height = Math.max(height >> 1, 1);
            }
        }

        return dds;
    }
}

typedef Dds = {
    var mipmaps:Array<DdsMipmap>;
    var width:Int;
    var height:Int;
    var format:Dynamic;
    var mipmapCount:Int;
    var isCubemap:Bool;
}

typedef DdsMipmap = {
    var data:ByteArray;
    var width:Int;
    var height:Int;
}