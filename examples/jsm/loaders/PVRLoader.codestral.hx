import three.loaders.CompressedTextureLoader;
import three.constants.TextureConstants;
import three.textures.TextureFormat;

class PVRLoader extends CompressedTextureLoader {

    public function new(manager:Loader) {
        super(manager);
    }

    public function parse(buffer:ArrayBuffer, loadMipmaps:Bool):Object {
        var headerLengthInt:Int = 13;
        var header:Array<Int> = [];
        for (i in 0...headerLengthInt) {
            header.push(buffer.getUint32(i * 4));
        }

        var pvrDatas:Object = {
            buffer: buffer,
            header: header,
            loadMipmaps: loadMipmaps
        };

        if (header[0] === 0x03525650) {
            return this.parseV3(pvrDatas);
        } else if (header[11] === 0x21525650) {
            return this.parseV2(pvrDatas);
        } else {
            trace("THREE.PVRLoader: Unknown PVR format.");
        }

        return null;
    }

    private function parseV3(pvrDatas:Object):Object {
        var header:Array<Int> = pvrDatas.header;
        var bpp:Int;
        var format:TextureFormat;

        var metaLen = header[12];
        var pixelFormat = header[2];
        var height = header[6];
        var width = header[7];
        var numFaces = header[10];
        var numMipmaps = header[11];

        switch(pixelFormat) {
            case 0:
                bpp = 2;
                format = TextureFormat.RGB_PVRTC_2BPPV1_Format;
                break;
            case 1:
                bpp = 2;
                format = TextureFormat.RGBA_PVRTC_2BPPV1_Format;
                break;
            case 2:
                bpp = 4;
                format = TextureFormat.RGB_PVRTC_4BPPV1_Format;
                break;
            case 3:
                bpp = 4;
                format = TextureFormat.RGBA_PVRTC_4BPPV1_Format;
                break;
            default:
                trace("THREE.PVRLoader: Unsupported PVR format: " + pixelFormat);
        }

        pvrDatas.dataPtr = 52 + metaLen;
        pvrDatas.bpp = bpp;
        pvrDatas.format = format;
        pvrDatas.width = width;
        pvrDatas.height = height;
        pvrDatas.numSurfaces = numFaces;
        pvrDatas.numMipmaps = numMipmaps;
        pvrDatas.isCubemap = (numFaces === 6);

        return this.extract(pvrDatas);
    }

    private function parseV2(pvrDatas:Object):Object {
        var header:Array<Int> = pvrDatas.header;

        var headerLength = header[0];
        var height = header[1];
        var width = header[2];
        var numMipmaps = header[3];
        var flags = header[4];
        var bitmaskAlpha = header[10];
        var numSurfs = header[12];

        var TYPE_MASK = 0xff;
        var PVRTC_2 = 24;
        var PVRTC_4 = 25;

        var formatFlags = flags & TYPE_MASK;

        var bpp:Int;
        var format:TextureFormat;
        var _hasAlpha = bitmaskAlpha > 0;

        if (formatFlags === PVRTC_4) {
            format = _hasAlpha ? TextureFormat.RGBA_PVRTC_4BPPV1_Format : TextureFormat.RGB_PVRTC_4BPPV1_Format;
            bpp = 4;
        } else if (formatFlags === PVRTC_2) {
            format = _hasAlpha ? TextureFormat.RGBA_PVRTC_2BPPV1_Format : TextureFormat.RGB_PVRTC_2BPPV1_Format;
            bpp = 2;
        } else {
            trace("THREE.PVRLoader: Unknown PVR format: " + formatFlags);
        }

        pvrDatas.dataPtr = headerLength;
        pvrDatas.bpp = bpp;
        pvrDatas.format = format;
        pvrDatas.width = width;
        pvrDatas.height = height;
        pvrDatas.numSurfaces = numSurfs;
        pvrDatas.numMipmaps = numMipmaps + 1;
        pvrDatas.isCubemap = (numSurfs === 6);

        return this.extract(pvrDatas);
    }

    private function extract(pvrDatas:Object):Object {
        var pvr:Object = {
            mipmaps: [],
            width: pvrDatas.width,
            height: pvrDatas.height,
            format: pvrDatas.format,
            mipmapCount: pvrDatas.numMipmaps,
            isCubemap: pvrDatas.isCubemap
        };

        var buffer:ArrayBuffer = pvrDatas.buffer;

        var dataOffset = pvrDatas.dataPtr;
        var dataSize = 0;
        var blockSize = 0;
        var blockWidth = 0;
        var blockHeight = 0;
        var widthBlocks = 0;
        var heightBlocks = 0;

        var bpp = pvrDatas.bpp;
        var numSurfs = pvrDatas.numSurfaces;

        if (bpp === 2) {
            blockWidth = 8;
            blockHeight = 4;
        } else {
            blockWidth = 4;
            blockHeight = 4;
        }

        blockSize = (blockWidth * blockHeight) * bpp / 8;

        pvr.mipmaps.length = pvrDatas.numMipmaps * numSurfs;

        var mipLevel = 0;

        while (mipLevel < pvrDatas.numMipmaps) {
            var sWidth = pvrDatas.width >> mipLevel;
            var sHeight = pvrDatas.height >> mipLevel;

            widthBlocks = sWidth / blockWidth;
            heightBlocks = sHeight / blockHeight;

            if (widthBlocks < 2) widthBlocks = 2;
            if (heightBlocks < 2) heightBlocks = 2;

            dataSize = widthBlocks * heightBlocks * blockSize;

            for (var surfIndex = 0; surfIndex < numSurfs; surfIndex++) {
                var byteArray = new haxe.io.Bytes(buffer, dataOffset, dataSize);

                var mipmap:Object = {
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
}