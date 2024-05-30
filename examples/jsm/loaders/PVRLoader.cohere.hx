import haxe.io.Bytes;

class PVRLoader {
    public function new() { }

    public function parse(buffer: Bytes, loadMipmaps: Bool): Void {
        var headerLengthInt = 13;
        var header = buffer.getInt32Array(0, headerLengthInt);

        if (header[0] == 0x03525650) {
            // PVR v3
            _parseV3({ buffer: buffer, header: header, loadMipmaps: loadMipmaps });
        } else if (header[11] == 0x21525650) {
            // PVR v2
            _parseV2({ buffer: buffer, header: header, loadMipmaps: loadMipmaps });
        } else {
            trace("PVRLoader: Unknown PVR format.");
        }
    }
}

function _parseV3(pvrDatas: { buffer: Bytes, header: Int32Array, loadMipmaps: Bool }) {
    var header = pvrDatas.header;
    var bpp: Int, format: Int;

    var metaLen = header[12];
    var pixelFormat = header[2];
    var height = header[6];
    var width = header[7];
    var numFaces = header[10];
    var numMipmaps = header[11];

    switch (pixelFormat) {
        case 0: // PVRTC 2bpp RGB
            bpp = 2;
            format = RGB_PVRTC_2BPPV1_Format;
            break;
        case 1: // PVRTC 2bpp RGBA
            bpp = 2;
            format = RGBA_PVRTC_2BPPV1_Format;
            break;
        case 2: // PVRTC 4bpp RGB
            bpp = 4;
            format = RGB_PVRTC_4BPPV1_Format;
            break;
        case 3: // PVRTC 4bpp RGBA
            bpp = 4;
            format = RGBA_PVRTC_4BPPV1_Format;
            break;
        default:
            trace("PVRLoader: Unsupported PVR format: " + pixelFormat);
    }

    pvrDatas.dataPtr = 52 + metaLen;
    pvrDatas.bpp = bpp;
    pvrDatas.format = format;
    pvrDatas.width = width;
    pvrDatas.height = height;
    pvrDatas.numSurfaces = numFaces;
    pvrDatas.numMipmaps = numMipmaps;
    pvrDatas.isCubemap = (numFaces == 6);

    _extract(pvrDatas);
}

function _parseV2(pvrDatas: { buffer: Bytes, header: Int32Array, loadMipmaps: Bool }) {
    var header = pvrDatas.header;

    var headerLength = header[0];
    var height = header[1];
    var width = header[2];
    var numMipmaps = header[3];
    var flags = header[4];
    var numSurfs = header[12];

    var TYPE_MASK = 0xff;
    var PVRTC_2 = 24;
    var PVRTC_4 = 25;

    var formatFlags = flags & TYPE_MASK;

    var bpp: Int, format: Int;
    var _hasAlpha = (header[10] > 0);

    if (formatFlags == PVRTC_4) {
        format = _hasAlpha ? RGBA_PVRTC_4BPPV1_Format : RGB_PVRTC_4BPPV1_Format;
        bpp = 4;
    } else if (formatFlags == PVRTC_2) {
        format = _hasAlpha ? RGBA_PVRTC_2BPPV1_Format : RGB_PVRTC_2BPPV1_Format;
        bpp = 2;
    } else {
        trace("PVRLoader: Unknown PVR format: " + formatFlags);
    }

    pvrDatas.dataPtr = headerLength;
    pvrDatas.bpp = bpp;
    pvrDatas.format = format;
    pvrDatas.width = width;
    pvrDatas.height = height;
    pvrDatas.numSurfaces = numSurfs;
    pvrDatas.numMipmaps = numMipmaps + 1;
    pvrDatas.isCubemap = (numSurfs == 6);

    _extract(pvrDatas);
}

function _extract(pvrDatas: { buffer: Bytes, bpp: Int, format: Int, width: Int, height: Int, numSurfaces: Int, numMipmaps: Int, isCubemap: Bool, dataPtr: Int }) {
    var pvr = {
        mipmaps: [],
        width: pvrDatas.width,
        height: pvrDatas.height,
        format: pvrDatas.format,
        mipmapCount: pvrDatas.numMipmaps,
        isCubemap: pvrDatas.isCubemap
    };

    var buffer = pvrDatas.buffer;

    var dataOffset = pvrDatas.dataPtr;
    var dataSize: Int, blockSize: Int, blockWidth: Int, blockHeight: Int, widthBlocks: Int, heightBlocks: Int;

    var bpp = pvrDatas.bpp;
    var numSurfs = pvrDatas.numSurfaces;

    if (bpp == 2) {
        blockWidth = 8;
        blockHeight = 4;
    } else {
        blockWidth = 4;
        blockHeight = 4;
    }

    blockSize = (blockWidth * blockHeight) * bpp / 8;

    pvr.mipmaps.length = pvrDatas.numMipmaps * numSurfs;

    var mipLevel: Int = 0;
    while (mipLevel < pvrDatas.numMipmaps) {
        var sWidth = pvrDatas.width >> mipLevel;
        var sHeight = pvrDatas.height >> mipLevel;

        widthBlocks = Std.int(sWidth / blockWidth);
        heightBlocks = Std.int(sHeight / blockHeight);

        if (widthBlocks < 2) widthBlocks = 2;
        if (heightBlocks < 2) heightBlocks = 2;

        dataSize = widthBlocks * heightBlocks * blockSize;

        var surfIndex: Int;
        for (surfIndex = 0; surfIndex < numSurfs; surfIndex++) {
            var byteArray = buffer.getBytes(dataOffset, dataSize);

            var mipmap = {
                data: byteArray,
                width: sWidth,
                height: sHeight
            };

            pvr.mipmaps[surfIndex * pvrDatas.numMipmaps + mipLevel] = mipmap;

            dataOffset += dataSize;
        }

        mipLevel++;
    }

    return pvr;
}

enum RGB_PVRTC_2BPPV1_Format { }
enum RGBA_PVRTC_2BPPV1_Format { }
enum RGB_PVRTC_4BPPV1_Format { }
enum RGBA_PVRTC_4BPPV1_Format { }