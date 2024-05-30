import three.CompressedTextureLoader;
import three.RGBA_PVRTC_2BPPV1_Format;
import three.RGBA_PVRTC_4BPPV1_Format;
import three.RGB_PVRTC_2BPPV1_Format;
import three.RGB_PVRTC_4BPPV1_Format;

/*
 *	 PVR v2 (legacy) parser
 *   TODO : Add Support for PVR v3 format
 *   TODO : implement loadMipmaps option
 */

class PVRLoader extends CompressedTextureLoader {

	public function new(manager:Dynamic) {
		super(manager);
	}

	public function parse(buffer:haxe.io.Bytes, loadMipmaps:Bool):Dynamic {

		var headerLengthInt = 13;
		var header = haxe.io.Bytes.ofData(buffer.b).sub(0, headerLengthInt).toUInt32Array();

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

			trace('THREE.PVRLoader: Unknown PVR format.');

		}

	}

	private function _parseV3(pvrDatas:Dynamic):Dynamic {

		var header = pvrDatas.header;
		var bpp:Int, format:Int;


		var metaLen = header[12],
			pixelFormat = header[2],
			height = header[6],
			width = header[7],
			// numSurfs = header[9],
			numFaces = header[10],
			numMipmaps = header[11];

		switch (pixelFormat) {

			case 0 : // PVRTC 2bpp RGB
				bpp = 2;
				format = RGB_PVRTC_2BPPV1_Format;
				break;

			case 1 : // PVRTC 2bpp RGBA
				bpp = 2;
				format = RGBA_PVRTC_2BPPV1_Format;
				break;

			case 2 : // PVRTC 4bpp RGB
				bpp = 4;
				format = RGB_PVRTC_4BPPV1_Format;
				break;

			case 3 : // PVRTC 4bpp RGBA
				bpp = 4;
				format = RGBA_PVRTC_4BPPV1_Format;
				break;

			default :
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

		var header = pvrDatas.header;

		var headerLength = header[0],
			height = header[1],
			width = header[2],
			numMipmaps = header[3],
			flags = header[4],
			// dataLength = header[5],
			// bpp =  header[6],
			// bitmaskRed = header[7],
			// bitmaskGreen = header[8],
			// bitmaskBlue = header[9],
			bitmaskAlpha = header[10],
			// pvrTag = header[11],
			numSurfs = header[12];


		var TYPE_MASK = 0xff;
		var PVRTC_2 = 24,
			PVRTC_4 = 25;

		var formatFlags = flags & TYPE_MASK;

		var bpp:Int, format:Int;
		var _hasAlpha = bitmaskAlpha > 0;

		if (formatFlags == PVRTC_4) {

			format = _hasAlpha ? RGBA_PVRTC_4BPPV1_Format : RGB_PVRTC_4BPPV1_Format;
			bpp = 4;

		} else if (formatFlags == PVRTC_2) {

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

		var pvr = {
			mipmaps: [],
			width: pvrDatas.width,
			height: pvrDatas.height,
			format: pvrDatas.format,
			mipmapCount: pvrDatas.numMipmaps,
			isCubemap: pvrDatas.isCubemap
		};

		var buffer = pvrDatas.buffer;

		var dataOffset = pvrDatas.dataPtr,
			dataSize = 0,
			blockSize = 0,
			blockWidth = 0,
			blockHeight = 0,
			widthBlocks = 0,
			heightBlocks = 0;

		var bpp = pvrDatas.bpp,
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

		var mipLevel = 0;

		while (mipLevel < pvrDatas.numMipmaps) {

			var sWidth = pvrDatas.width >> mipLevel,
				sHeight = pvrDatas.height >> mipLevel;

			widthBlocks = sWidth / blockWidth;
			heightBlocks = sHeight / blockHeight;

			// Clamp to minimum number of blocks
			if (widthBlocks < 2) widthBlocks = 2;
			if (heightBlocks < 2) heightBlocks = 2;

			dataSize = widthBlocks * heightBlocks * blockSize;

			for (surfIndex in 0...numSurfs) {

				var byteArray = haxe.io.Bytes.ofData(buffer.b).sub(dataOffset, dataSize).toUInt8Array();

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

}