package three.js.examples.jsm.loaders;

import three.CompressedTextureLoader;
import three.RGBAFormat;
import three.RGBA_S3TC_DXT1_Format;
import three.RGBA_S3TC_DXT3_Format;
import three.RGBA_S3TC_DXT5_Format;
import three.RGB_ETC1_Format;
import three.RGB_S3TC_DXT1_Format;
import three.RGB_BPTC_SIGNED_Format;
import three.RGB_BPTC_UNSIGNED_Format;

class DDSLoader extends CompressedTextureLoader {
    public function new(manager:Dynamic) {
        super(manager);
    }

    public function parse(buffer:Array<Int>, loadMipmaps:Bool):Dynamic {
        var dds = {
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

        const DDS_MAGIC = 0x20534444;

        const DDSD_MIPMAPCOUNT = 0x20000;
        const DDSCAPS2_CUBEMAP = 0x200;
        const DDSCAPS2_CUBEMAP_POSITIVEX = 0x400;
        const DDSCAPS2_CUBEMAP_NEGATIVEX = 0x800;
        const DDSCAPS2_CUBEMAP_POSITIVEY = 0x1000;
        const DDSCAPS2_CUBEMAP_NEGATIVEY = 0x2000;
        const DDSCAPS2_CUBEMAP_POSITIVEZ = 0x4000;
        const DDSCAPS2_CUBEMAP_NEGATIVEZ = 0x8000;

        const DXGI_FORMAT_BC6H_UF16 = 95;
        const DXGI_FORMAT_BC6H_SF16 = 96;

        function fourCCToInt32(value:String):Int {
            return value.charCodeAt(0) + (value.charCodeAt(1) << 8) + (value.charCodeAt(2) << 16) + (value.charCodeAt(3) << 24);
        }

        function int32ToFourCC(value:Int):String {
            return String.fromCharCode(value & 0xff, (value >> 8) & 0xff, (value >> 16) & 0xff, (value >> 24) & 0xff);
        }

        function loadARGBMip(buffer:Array<Int>, dataOffset:Int, width:Int, height:Int):Array<Int> {
            var dataLength = width * height * 4;
            var srcBuffer = new Uint8Array(buffer, dataOffset, dataLength);
            var byteArray = new Uint8Array(dataLength);
            var dst = 0;
            var src = 0;
            for (y in 0...height) {
                for (x in 0...width) {
                    var b = srcBuffer[src++]; srcBuffer[src++];
                    var g = srcBuffer[src++]; srcBuffer[src++];
                    var r = srcBuffer[src++]; srcBuffer[src++];
                    var a = srcBuffer[src++]; srcBuffer[src++];
                    byteArray[dst++] = r; //r
                    byteArray[dst++] = g; //g
                    byteArray[dst++] = b; //b
                    byteArray[dst++] = a; //a
                }
            }
            return byteArray;
        }

        const FOURCC_DXT1 = fourCCToInt32('DXT1');
        const FOURCC_DXT3 = fourCCToInt32('DXT3');
        const FOURCC_DXT5 = fourCCToInt32('DXT5');
        const FOURCC_ETC1 = fourCCToInt32('ETC1');
        const FOURCC_DX10 = fourCCToInt32('DX10');

        const headerLengthInt = 31; // The header length in 32 bit ints
        const extendedHeaderLengthInt = 5; // The extended header length in 32 bit ints

        const off_magic = 0;
        const off_size = 1;
        const off_flags = 2;
        const off_height = 3;
        const off_width = 4;

        const off_mipmapCount = 7;
        const off_pfFourCC = 21;
        const off_RGBBitCount = 22;
        const off_RBitMask = 23;
        const off_GBitMask = 24;
        const off_BBitMask = 25;
        const off_ABitMask = 26;
        const off_caps2 = 28;

        const off_dxgiFormat = 0;

        var header = new Int32Array(buffer, 0, headerLengthInt);

        if (header[off_magic] != DDS_MAGIC) {
            trace('THREE.DDSLoader.parse: Invalid magic number in DDS header.');
            return dds;
        }

        var blockBytes:Int;
        var fourCC = header[off_pfFourCC];

        var isRGBAUncompressed = false;

        var dataOffset = header[off_size] + 4;

        switch (fourCC) {
            case FOURCC_DXT1:
                blockBytes = 8;
                dds.format = RGB_S3TC_DXT1_Format;
            case FOURCC_DXT3:
                blockBytes = 16;
                dds.format = RGBA_S3TC_DXT3_Format;
            case FOURCC_DXT5:
                blockBytes = 16;
                dds.format = RGBA_S3TC_DXT5_Format;
            case FOURCC_ETC1:
                blockBytes = 8;
                dds.format = RGB_ETC1_Format;
            case FOURCC_DX10:
                dataOffset += extendedHeaderLengthInt * 4;
                var extendedHeader = new Int32Array(buffer, (headerLengthInt + 1) * 4, extendedHeaderLengthInt);
                var dxgiFormat = extendedHeader[off_dxgiFormat];
                switch (dxgiFormat) {
                    case DXGI_FORMAT_BC6H_SF16:
                        blockBytes = 16;
                        dds.format = RGB_BPTC_SIGNED_Format;
                    case DXGI_FORMAT_BC6H_UF16:
                        blockBytes = 16;
                        dds.format = RGB_BPTC_UNSIGNED_Format;
                    default:
                        trace('THREE.DDSLoader.parse: Unsupported DXGI_FORMAT code ' + dxgiFormat);
                        return dds;
                }
            default:
                if (header[off_RGBBitCount] == 32 && header[off_RBitMask] & 0xff0000 && header[off_GBitMask] & 0xff00 && header[off_BBitMask] & 0xff && header[off_ABitMask] & 0xff000000) {
                    isRGBAUncompressed = true;
                    blockBytes = 64;
                    dds.format = RGBAFormat;
                } else {
                    trace('THREE.DDSLoader.parse: Unsupported FourCC code ' + int32ToFourCC(fourCC));
                    return dds;
                }
        }

        dds.mipmapCount = 1;

        if (header[off_flags] & DDSD_MIPMAPCOUNT && loadMipmaps !== false) {
            dds.mipmapCount = Math.max(1, header[off_mipmapCount]);
        }

        var caps2 = header[off_caps2];
        dds.isCubemap = caps2 & DDSCAPS2_CUBEMAP ? true : false;
        if (dds.isCubemap && (! (caps2 & DDSCAPS2_CUBEMAP_POSITIVEX) || ! (caps2 & DDSCAPS2_CUBEMAP_NEGATIVEX) || ! (caps2 & DDSCAPS2_CUBEMAP_POSITIVEY) || ! (caps2 & DDSCAPS2_CUBEMAP_NEGATIVEY) || ! (caps2 & DDSCAPS2_CUBEMAP_POSITIVEZ) || ! (caps2 & DDSCAPS2_CUBEMAP_NEGATIVEZ))) {
            trace('THREE.DDSLoader.parse: Incomplete cubemap faces');
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
                var byteArray:Array<Int>;
                var dataLength;

                if (isRGBAUncompressed) {
                    byteArray = loadARGBMip(buffer, dataOffset, width, height);
                    dataLength = byteArray.length;
                } else {
                    dataLength = Math.max(4, width) / 4 * Math.max(4, height) / 4 * blockBytes;
                    byteArray = new Uint8Array(buffer, dataOffset, dataLength);
                }

                var mipmap = { data: byteArray, width: width, height: height };
                dds.mipmaps.push(mipmap);

                dataOffset += dataLength;

                width = Math.max(width >> 1, 1);
                height = Math.max(height >> 1, 1);
            }
        }

        return dds;
    }
}