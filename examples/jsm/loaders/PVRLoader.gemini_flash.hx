import three.loaders.CompressedTextureLoader;
import three.constants.TextureFormats;

class PVRLoader extends CompressedTextureLoader {

	public function new(manager:Dynamic = null) {
		super(manager);
	}

	public function parse(buffer:haxe.io.Bytes, loadMipmaps:Bool):Dynamic {
		const headerLengthInt = 13;
		const header = new Uint32Array(buffer.get(0, headerLengthInt * 4));

		const pvrDatas = {
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
			console.error('THREE.PVRLoader: Unknown PVR format.');
		}
	}
}

function _parseV3(pvrDatas:Dynamic):Dynamic {
	const header = pvrDatas.header;
	var bpp:Int, format:Int;

	const metaLen = header[12],
		pixelFormat = header[2],
		height = header[6],
		width = header[7],
		// numSurfs = header[ 9 ],
		numFaces = header[10],
		numMipmaps = header[11];

	switch (pixelFormat) {
		case 0: // PVRTC 2bpp RGB
			bpp = 2;
			format = TextureFormats.RGB_PVRTC_2BPPV1_Format;
			break;
		case 1: // PVRTC 2bpp RGBA
			bpp = 2;
			format = TextureFormats.RGBA_PVRTC_2BPPV1_Format;
			break;
		case 2: // PVRTC 4bpp RGB
			bpp = 4;
			format = TextureFormats.RGB_PVRTC_4BPPV1_Format;
			break;
		case 3: // PVRTC 4bpp RGBA
			bpp = 4;
			format = TextureFormats.RGBA_PVRTC_4BPPV1_Format;
			break;
		default:
			console.error('THREE.PVRLoader: Unsupported PVR format:', pixelFormat);
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

function _parseV2(pvrDatas:Dynamic):Dynamic {
	const header = pvrDatas.header;

	const headerLength = header[0],
		height = header[1],
		width = header[2],
		numMipmaps = header[3],
		flags = header[4],
		// dataLength = header[ 5 ],
		// bpp =  header[ 6 ],
		// bitmaskRed = header[ 7 ],
		// bitmaskGreen = header[ 8 ],
		// bitmaskBlue = header[ 9 ],
		bitmaskAlpha = header[10],
		// pvrTag = header[ 11 ],
		numSurfs = header[12];

	const TYPE_MASK = 0xff;
	const PVRTC_2 = 24,
		PVRTC_4 = 25;

	const formatFlags = flags & TYPE_MASK;

	var bpp:Int, format:Int;
	const _hasAlpha = bitmaskAlpha > 0;

	if (formatFlags == PVRTC_4) {
		format = _hasAlpha ? TextureFormats.RGBA_PVRTC_4BPPV1_Format : TextureFormats.RGB_PVRTC_4BPPV1_Format;
		bpp = 4;
	} else if (formatFlags == PVRTC_2) {
		format = _hasAlpha ? TextureFormats.RGBA_PVRTC_2BPPV1_Format : TextureFormats.RGB_PVRTC_2BPPV1_Format;
		bpp = 2;
	} else {
		console.error('THREE.PVRLoader: Unknown PVR format:', formatFlags);
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
	pvrDatas.isCubemap = (numSurfs == 6);

	return _extract(pvrDatas);
}

function _extract(pvrDatas:Dynamic):Dynamic {
	const pvr = {
		mipmaps: [],
		width: pvrDatas.width,
		height: pvrDatas.height,
		format: pvrDatas.format,
		mipmapCount: pvrDatas.numMipmaps,
		isCubemap: pvrDatas.isCubemap
	};

	const buffer = pvrDatas.buffer;

	var dataOffset:Int = pvrDatas.dataPtr,
		dataSize:Int = 0,
		blockSize:Int = 0,
		blockWidth:Int = 0,
		blockHeight:Int = 0,
		widthBlocks:Int = 0,
		heightBlocks:Int = 0;

	const bpp = pvrDatas.bpp,
		numSurfs = pvrDatas.numSurfaces;

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
		const sWidth = pvrDatas.width >> mipLevel,
			sHeight = pvrDatas.height >> mipLevel;

		widthBlocks = sWidth / blockWidth;
		heightBlocks = sHeight / blockHeight;

		// Clamp to minimum number of blocks
		if (widthBlocks < 2) widthBlocks = 2;
		if (heightBlocks < 2) heightBlocks = 2;

		dataSize = widthBlocks * heightBlocks * blockSize;

		for (var surfIndex:Int = 0; surfIndex < numSurfs; surfIndex++) {
			const byteArray = new Uint8Array(buffer.get(dataOffset, dataSize));

			const mipmap = {
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