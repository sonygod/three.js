import three.examples.jsm.loaders.CompressedTextureLoader;
import three.examples.jsm.loaders.RGBA_PVRTC_2BPPV1_Format;
import three.examples.jsm.loaders.RGBA_PVRTC_4BPPV1_Format;
import three.examples.jsm.loaders.RGB_PVRTC_2BPPV1_Format;
import three.examples.jsm.loaders.RGB_PVRTC_4BPPV1_Format;

class PVRLoader extends CompressedTextureLoader {

	public function new(manager:Dynamic) {
		super(manager);
	}

	public function parse(buffer:Dynamic, loadMipmaps:Dynamic):Dynamic {

		var headerLengthInt:Int = 13;
		var header:Uint32Array = new Uint32Array(buffer, 0, headerLengthInt);

		var pvrDatas:Dynamic = {
			buffer: buffer,
			header: header,
			loadMipmaps: loadMipmaps
		};

		if (header[0] === 0x03525650) {

			// PVR v3

			return _parseV3(pvrDatas);

		} else if (header[11] === 0x21525650) {

			// PVR v2

			return _parseV2(pvrDatas);

		} else {

			trace('THREE.PVRLoader: Unknown PVR format.');

		}

	}

}

private function _parseV3(pvrDatas:Dynamic):Dynamic {

	var header:Uint32Array = pvrDatas.header;
	var bpp:Int, format:Dynamic;

	var metaLen:Int = header[12],
		pixelFormat:Int = header[2],
		height:Int = header[6],
		width:Int = header[7],
		numSurfs:Int = header[9],
		numFaces:Int = header[10],
		numMipmaps:Int = header[11];

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
			trace('THREE.PVRLoader: Unsupported PVR format:', pixelFormat);

	}

	pvrDatas.dataPtr = 52 + metaLen;
	pvrDatas.bpp = bpp;
	pvrDatas.format = format;
	pvrDatas.width = width;
	pvrDatas.height = height;
	pvrDatas.numSurfaces = numFaces;
	pvrDatas.numMipmaps = numMipmaps;
	pvrDatas.isCubemap = (numFaces === 6);

	return _extract(pvrDatas);

}

private function _parseV2(pvrDatas:Dynamic):Dynamic {

	var header:Uint32Array = pvrDatas.header;

	var headerLength:Int = header[0],
		height:Int = header[1],
		width:Int = header[2],
		numMipmaps:Int = header[3],
		flags:Int = header[4],
		// dataLength:Int = header[5],
		// bpp:Int = header[6],
		// bitmaskRed:Int = header[7],
		// bitmaskGreen:Int = header[8],
		// bitmaskBlue:Int = header[9],
		bitmaskAlpha:Int = header[10],
		// pvrTag:Int = header[11],
		numSurfs:Int = header[12];

	var TYPE_MASK:Int = 0xff;
	var PVRTC_2:Int = 24,
		PVRTC_4:Int = 25;

	var formatFlags:Int = flags & TYPE_MASK;

	var bpp:Int, format:Dynamic;
	var _hasAlpha:Bool = bitmaskAlpha > 0;

	if (formatFlags === PVRTC_4) {

		format = _hasAlpha ? RGBA_PVRTC_4BPPV1_Format : RGB_PVRTC_4BPPV1_Format;
		bpp = 4;

	} else if (formatFlags === PVRTC_2) {

		format = _hasAlpha ? RGBA_PVRTC_2BPPV1_Format : RGB_PVRTC_2BPPV1_Format;
		bpp = 2;

	} else {

		trace('THREE.PVRLoader: Unknown PVR format:', formatFlags);

	}

	pvrDatas.dataPtr = headerLength;
	pvrDatas.bpp = bpp;
	pvrDatas.format = format;
	pvrDatas.width = width;
	pvrDatas.height = height;
	pvrDatas.numSurfaces = numSurfs;
	pvrDatas.numMipmaps = numMipmaps + 1;

	// guess cubemap type seems tricky in v2
	// it juste a pvr containing 6 surface (no explicit cubemap type)
	pvrDatas.isCubemap = (numSurfs === 6);

	return _extract(pvrDatas);

}

private function _extract(pvrDatas:Dynamic):Dynamic {

	var pvr:Dynamic = {
		mipmaps: [],
		width: pvrDatas.width,
		height: pvrDatas.height,
		format: pvrDatas.format,
		mipmapCount: pvrDatas.numMipmaps,
		isCubemap: pvrDatas.isCubemap
	};

	var buffer:Dynamic = pvrDatas.buffer;

	var dataOffset:Int = pvrDatas.dataPtr,
		dataSize:Int = 0,
		blockSize:Int = 0,
		blockWidth:Int = 0,
		blockHeight:Int = 0,
		widthBlocks:Int = 0,
		heightBlocks:Int = 0;

	var bpp:Int = pvrDatas.bpp,
		numSurfs:Int = pvrDatas.numSurfaces;

	if (bpp === 2) {

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

		var sWidth:Int = pvrDatas.width >> mipLevel,
			sHeight:Int = pvrDatas.height >> mipLevel;

		widthBlocks = sWidth / blockWidth;
		heightBlocks = sHeight / blockHeight;

		// Clamp to minimum number of blocks
		if (widthBlocks < 2) widthBlocks = 2;
		if (heightBlocks < 2) heightBlocks = 2;

		dataSize = widthBlocks * heightBlocks * blockSize;

		for (surfIndex in 0...numSurfs) {

			var byteArray:Uint8Array = new Uint8Array(buffer, dataOffset, dataSize);

			var mipmap:Dynamic = {
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