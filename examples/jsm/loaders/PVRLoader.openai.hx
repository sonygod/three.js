package three.js.examples.jsm.loaders;

import three.js.loaders.CompressedTextureLoader;
import three.js_TextureFormat.RGBA_PVRTC_2BPPV1_Format;
import three.js_TextureFormat.RGBA_PVRTC_4BPPV1_Format;
import three.js_TextureFormat.RGB_PVRTC_2BPPV1_Format;
import three.js_TextureFormat.RGB_PVRTC_4BPPV1_Format;

class PVRLoader extends CompressedTextureLoader {
    public function new(manager:Loader.Manager) {
        super(manager);
    }

    override public function parse(buffer: js.lib.Uint8Array, loadMipmaps:Bool):Dynamic {
        var headerLength:Int = 13;
        var header:js.lib.Uint32Array = new js.lib.Uint32Array(buffer, 0, headerLength);

        var pvrDatas = {
            buffer: buffer,
            header: header,
            loadMipmaps: loadMipmaps
        };

        if (header[0] == 0x03525650) {
            // PVR v3
            return _parseV3(pvrDatas);
        } else if (header[11] == 0x21525650) {
            // PVR v2
            return _parseV2(pvrDatas);
        } else {
            Console.error('THREE.PVRLoader: Unknown PVR format.');
        }

        return null;
    }
}

function _parseV3(pvrDatas:Dynamic) {
    var header:js.lib.Uint32Array = pvrDatas.header;
    var bpp:Int;
    var format:TextureFormat;

    var metaLen:Int = header[12];
    var pixelFormat:Int = header[2];
    var height:Int = header[6];
    var width:Int = header[7];
    var numFaces:Int = header[10];
    var numMipmaps:Int = header[11];

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
            Console.error('THREE.PVRLoader: Unsupported PVR format:', pixelFormat);
    }

    pvrDatas.dataPtr = 52 + metaLen;
    pvrDatas.bpp = bpp;
    pvrDatas.format = format;
    pvrDatas.width = width;
    pvrDatas.height = height;
    pvrDatas.numSurfaces = numFaces;
    pvrDatas.numMipmaps = numMipmaps;
    pvrDatas.isCubemap = (numFaces == 6);

    return _extract(pvrDatas);
}

function _parseV2(pvrDatas:Dynamic) {
    var header:js.lib.Uint32Array = pvrDatas.header;

    var headerLength:Int = header[0];
    var height:Int = header[1];
    var width:Int = header[2];
    var numMipmaps:Int = header[3];
    var flags:Int = header[4];
    var bitmaskAlpha:Int = header[10];
    var numSurfs:Int = header[12];

    const TYPE_MASK:Int = 0xff;
    const PVRTC_2:Int = 24;
    const PVRTC_4:Int = 25;

    var formatFlags:Int = flags & TYPE_MASK;

    var bpp:Int;
    var format:TextureFormat;

    if (formatFlags == PVRTC_4) {
        format = bitmaskAlpha > 0 ? RGBA_PVRTC_4BPPV1_Format : RGB_PVRTC_4BPPV1_Format;
        bpp = 4;
    } else if (formatFlags == PVRTC_2) {
        format = bitmaskAlpha > 0 ? RGBA_PVRTC_2BPPV1_Format : RGB_PVRTC_2BPPV1_Format;
        bpp = 2;
    } else {
        Console.error('THREE.PVRLoader: Unknown PVR format:', formatFlags);
    }

    pvrDatas.dataPtr = headerLength;
    pvrDatas.bpp = bpp;
    pvrDatas.format = format;
    pvrDatas.width = width;
    pvrDatas.height = height;
    pvrDatas.numSurfaces = numSurfs;
    pvrDatas.numMipmaps = numMipmaps + 1;

    pvrDatas.isCubemap = (numSurfs == 6);

    return _extract(pvrDatas);
}

function _extract(pvrDatas:Dynamic) {
    var pvr:Dynamic = {
        mipmaps: [],
        width: pvrDatas.width,
        height: pvrDatas.height,
        format: pvrDatas.format,
        mipmapCount: pvrDatas.numMipmaps,
        isCubemap: pvrDatas.isCubemap
    };

    var buffer:js.lib.Uint8Array = pvrDatas.buffer;

    var dataOffset:Int = pvrDatas.dataPtr;
    var dataSize:Int = 0;
    var blockSize:Int = 0;
    var blockWidth:Int = 0;
    var blockHeight:Int = 0;
    var widthBlocks:Int = 0;
    var heightBlocks:Int = 0;

    var bpp:Int = pvrDatas.bpp;
    var numSurfs:Int = pvrDatas.numSurfaces;

    if (bpp == 2) {
        blockWidth = 8;
        blockHeight = 4;
    } else {
        blockWidth = 4;
        blockHeight = 4;
    }

    blockSize = (blockWidth * blockHeight) * bpp / 8;

    pvr.mipmaps.length = pvrDatas.numMipmaps * numSurfs;

    var mipLevel:Int = 0;

    while (mipLevel < pvrDatas.numMipmaps) {
        var sWidth:Int = pvrDatas.width >> mipLevel;
        var sHeight:Int = pvrDatas.height >> mipLevel;

        widthBlocks = sWidth / blockWidth;
        heightBlocks = sHeight / blockHeight;

        // Clamp to minimum number of blocks
        if (widthBlocks < 2) widthBlocks = 2;
        if (heightBlocks < 2) heightBlocks = 2;

        dataSize = widthBlocks * heightBlocks * blockSize;

        for (surIndex in 0...numSurfs) {
            var byteArray:js.lib.Uint8Array = new js.lib.Uint8Array(buffer, dataOffset, dataSize);

            var mipmap:Dynamic = {
                data: byteArray,
                width: sWidth,
                height: sHeight
            };

            pvr.mipmaps[surIndex * pvrDatas.numMipmaps + mipLevel] = mipmap;

            dataOffset += dataSize;
        }

        mipLevel++;
    }

    return pvr;
}