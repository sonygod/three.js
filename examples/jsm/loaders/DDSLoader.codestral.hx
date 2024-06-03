import three.CompressedTextureLoader;
import three.RGBAFormat;
import three.RGBA_S3TC_DXT3_Format;
import three.RGBA_S3TC_DXT5_Format;
import three.RGB_ETC1_Format;
import three.RGB_S3TC_DXT1_Format;
import three.RGB_BPTC_SIGNED_Format;
import three.RGB_BPTC_UNSIGNED_Format;

class DDSLoader extends CompressedTextureLoader {
    public function new(manager: any) {
        super(manager);
    }

    public function parse(buffer: ArrayBuffer, loadMipmaps: Bool): DDS {
        var dds: DDS = { mipmaps: [], width: 0, height: 0, format: null, mipmapCount: 1 };

        var DDS_MAGIC = 0x20534444;
        var DDSD_MIPMAPCOUNT = 0x20000;
        var DDSCAPS2_CUBEMAP = 0x200;
        var DDSCAPS2_CUBEMAP_POSITIVEX = 0x400;
        var DDSCAPS2_CUBEMAP_NEGATIVEX = 0x800;
        var DDSCAPS2_CUBEMAP_POSITIVEY = 0x1000;
        var DDSCAPS2_CUBEMAP_NEGATIVEY = 0x2000;
        var DDSCAPS2_CUBEMAP_POSITIVEZ = 0x4000;
        var DDSCAPS2_CUBEMAP_NEGATIVEZ = 0x8000;
        var DXGI_FORMAT_BC6H_UF16 = 95;
        var DXGI_FORMAT_BC6H_SF16 = 96;

        function fourCCToInt32(value: String): Int {
            return value.charCodeAt(0) +
                   (value.charCodeAt(1) << 8) +
                   (value.charCodeAt(2) << 16) +
                   (value.charCodeAt(3) << 24);
        }

        function int32ToFourCC(value: Int): String {
            return String.fromCharCode(
                value & 0xff,
                (value >> 8) & 0xff,
                (value >> 16) & 0xff,
                (value >> 24) & 0xff
            );
        }

        function loadARGBMip(buffer: ArrayBuffer, dataOffset: Int, width: Int, height: Int): Uint8Array {
            var dataLength = width * height * 4;
            var srcBuffer = new Uint8Array(buffer, dataOffset, dataLength);
            var byteArray = new Uint8Array(dataLength);
            var dst: Int = 0;
            var src: Int = 0;
            for (var y = 0; y < height; y++) {
                for (var x = 0; x < width; x++) {
                    var b = srcBuffer[src]; src++;
                    var g = srcBuffer[src]; src++;
                    var r = srcBuffer[src]; src++;
                    var a = srcBuffer[src]; src++;
                    byteArray[dst] = r; dst++;
                    byteArray[dst] = g; dst++;
                    byteArray[dst] = b; dst++;
                    byteArray[dst] = a; dst++;
                }
            }
            return byteArray;
        }

        var FOURCC_DXT1 = fourCCToInt32("DXT1");
        var FOURCC_DXT3 = fourCCToInt32("DXT3");
        var FOURCC_DXT5 = fourCCToInt32("DXT5");
        var FOURCC_ETC1 = fourCCToInt32("ETC1");
        var FOURCC_DX10 = fourCCToInt32("DX10");

        var headerLengthInt = 31;
        var extendedHeaderLengthInt = 5;

        var off_magic = 0;
        var off_size = 1;
        var off_flags = 2;
        var off_height = 3;
        var off_width = 4;
        var off_mipmapCount = 7;
        var off_pfFourCC = 21;
        var off_RGBBitCount = 22;
        var off_RBitMask = 23;
        var off_GBitMask = 24;
        var off_BBitMask = 25;
        var off_ABitMask = 26;
        var off_caps2 = 28;
        var off_dxgiFormat = 0;

        var header = new Int32Array(buffer, 0, headerLengthInt);

        if (header[off_magic] !== DDS_MAGIC) {
            trace("THREE.DDSLoader.parse: Invalid magic number in DDS header.");
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
                var extendedHeader = new Int32Array(buffer, (headerLengthInt + 1) * 4, extendedHeaderLengthInt);
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
                        trace("THREE.DDSLoader.parse: Unsupported DXGI_FORMAT code " + dxgiFormat);
                        return dds;
                }
                break;
            default:
                if (header[off_RGBBitCount] === 32
                    && header[off_RBitMask] & 0xff0000
                    && header[off_GBitMask] & 0xff00
                    && header[off_BBitMask] & 0xff
                    && header[off_ABitMask] & 0xff000000) {
                    isRGBAUncompressed = true;
                    blockBytes = 64;
                    dds.format = RGBAFormat;
                } else {
                    trace("THREE.DDSLoader.parse: Unsupported FourCC code " + int32ToFourCC(fourCC));
                    return dds;
                }
        }

        dds.mipmapCount = 1;

        if (header[off_flags] & DDSD_MIPMAPCOUNT && loadMipmaps !== false) {
            dds.mipmapCount = Math.max(1, header[off_mipmapCount]);
        }

        var caps2 = header[off_caps2];
        dds.isCubemap = (caps2 & DDSCAPS2_CUBEMAP) ? true : false;
        if (dds.isCubemap && (
            !(caps2 & DDSCAPS2_CUBEMAP_POSITIVEX) ||
            !(caps2 & DDSCAPS2_CUBEMAP_NEGATIVEX) ||
            !(caps2 & DDSCAPS2_CUBEMAP_POSITIVEY) ||
            !(caps2 & DDSCAPS2_CUBEMAP_NEGATIVEY) ||
            !(caps2 & DDSCAPS2_CUBEMAP_POSITIVEZ) ||
            !(caps2 & DDSCAPS2_CUBEMAP_NEGATIVEZ)
        )) {
            trace("THREE.DDSLoader.parse: Incomplete cubemap faces");
            return dds;
        }

        dds.width = header[off_width];
        dds.height = header[off_height];

        var faces = dds.isCubemap ? 6 : 1;

        for (var face = 0; face < faces; face++) {
            var width = dds.width;
            var height = dds.height;

            for (var i = 0; i < dds.mipmapCount; i++) {
                var byteArray: Uint8Array;
                var dataLength: Int;

                if (isRGBAUncompressed) {
                    byteArray = loadARGBMip(buffer, dataOffset, width, height);
                    dataLength = byteArray.length;
                } else {
                    dataLength = Math.max(4, width) / 4 * Math.max(4, height) / 4 * blockBytes;
                    byteArray = new Uint8Array(buffer, dataOffset, dataLength);
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
    mipmaps: Array<{ data: Uint8Array, width: Int, height: Int }>,
    width: Int,
    height: Int,
    format: Int,
    mipmapCount: Int,
    isCubemap: Bool
};