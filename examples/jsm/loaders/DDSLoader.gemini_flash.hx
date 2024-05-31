import three.CompressedTextureLoader;
import three.RGBAFormat;
import three.RGBA_S3TC_DXT3_Format;
import three.RGBA_S3TC_DXT5_Format;
import three.RGB_ETC1_Format;
import three.RGB_S3TC_DXT1_Format;
import three.RGB_BPTC_SIGNED_Format;
import three.RGB_BPTC_UNSIGNED_Format;
import three.LoadingManager;
import js.lib.Int32Array;
import js.lib.Uint8Array;

class DDSLoader extends CompressedTextureLoader {

	public function new(manager:LoadingManager) {
		super(manager);
	}

	override public function parse(buffer: js.html.ArrayBuffer, loadMipmaps:Bool): { mipmaps:Array<{ data:Uint8Array, width:Int, height:Int }>, width:Int, height:Int, format:Int, mipmapCount:Int, isCubemap:Bool } {
		var dds = {mipmaps: [], width: 0, height: 0, format: 0, mipmapCount: 1, isCubemap: false};

		// Adapted from @toji's DDS utils
		// https://github.com/toji/webgl-texture-utils/blob/master/texture-util/dds.js

		// All values and structures referenced from:
		// http://msdn.microsoft.com/en-us/library/bb943991.aspx/

		inline var DDS_MAGIC = 0x20534444;

		// const DDSD_CAPS = 0x1;
		// const DDSD_HEIGHT = 0x2;
		// const DDSD_WIDTH = 0x4;
		// const DDSD_PITCH = 0x8;
		// const DDSD_PIXELFORMAT = 0x1000;
		inline var DDSD_MIPMAPCOUNT = 0x20000;
		// const DDSD_LINEARSIZE = 0x80000;
		// const DDSD_DEPTH = 0x800000;

		// const DDSCAPS_COMPLEX = 0x8;
		// const DDSCAPS_MIPMAP = 0x400000;
		// const DDSCAPS_TEXTURE = 0x1000;

		inline var DDSCAPS2_CUBEMAP = 0x200;
		inline var DDSCAPS2_CUBEMAP_POSITIVEX = 0x400;
		inline var DDSCAPS2_CUBEMAP_NEGATIVEX = 0x800;
		inline var DDSCAPS2_CUBEMAP_POSITIVEY = 0x1000;
		inline var DDSCAPS2_CUBEMAP_NEGATIVEY = 0x2000;
		inline var DDSCAPS2_CUBEMAP_POSITIVEZ = 0x4000;
		inline var DDSCAPS2_CUBEMAP_NEGATIVEZ = 0x8000;
		// const DDSCAPS2_VOLUME = 0x200000;

		// const DDPF_ALPHAPIXELS = 0x1;
		// const DDPF_ALPHA = 0x2;
		// const DDPF_FOURCC = 0x4;
		// const DDPF_RGB = 0x40;
		// const DDPF_YUV = 0x200;
		// const DDPF_LUMINANCE = 0x20000;

		inline var DXGI_FORMAT_BC6H_UF16 = 95;
		inline var DXGI_FORMAT_BC6H_SF16 = 96;

		function fourCCToInt32(value:String):Int {
			return value.charCodeAt(0) | (value.charCodeAt(1) << 8) | (value.charCodeAt(2) << 16) | (value.charCodeAt(3) << 24);
		}

		function int32ToFourCC(value:Int):String {
			return String.fromCharCode(value & 0xff) + String.fromCharCode((value >> 8) & 0xff) + String.fromCharCode((value >> 16) & 0xff)
				+ String.fromCharCode((value >> 24) & 0xff);
		}

		function loadARGBMip(buffer:Uint8Array, dataOffset:Int, width:Int, height:Int):Uint8Array {
			var dataLength = width * height * 4;
			var srcBuffer = new Uint8Array(buffer.buffer, dataOffset, dataLength);
			var byteArray = new Uint8Array(dataLength);
			var dst = 0;
			var src = 0;
			for (y in 0...height) {
				for (x in 0...width) {
					var b = srcBuffer[src++];
					var g = srcBuffer[src++];
					var r = srcBuffer[src++];
					var a = srcBuffer[src++];
					byteArray[dst++] = r; // r
					byteArray[dst++] = g; // g
					byteArray[dst++] = b; // b
					byteArray[dst++] = a; // a
				}
			}
			return byteArray;
		}

		inline var FOURCC_DXT1 = fourCCToInt32("DXT1");
		inline var FOURCC_DXT3 = fourCCToInt32("DXT3");
		inline var FOURCC_DXT5 = fourCCToInt32("DXT5");
		inline var FOURCC_ETC1 = fourCCToInt32("ETC1");
		inline var FOURCC_DX10 = fourCCToInt32("DX10");

		inline var headerLengthInt = 31; // The header length in 32 bit ints
		inline var extendedHeaderLengthInt = 5; // The extended header length in 32 bit ints

		// Offsets into the header array
		inline var off_magic = 0;
		inline var off_size = 1;
		inline var off_flags = 2;
		inline var off_height = 3;
		inline var off_width = 4;
		inline var off_mipmapCount = 7;
		// const off_pfFlags = 20;
		inline var off_pfFourCC = 21;
		inline var off_RGBBitCount = 22;
		inline var off_RBitMask = 23;
		inline var off_GBitMask = 24;
		inline var off_BBitMask = 25;
		inline var off_ABitMask = 26;

		// const off_caps = 27;
		inline var off_caps2 = 28;
		// const off_caps3 = 29;
		// const off_caps4 = 30;

		// If fourCC = DX10, the extended header starts after 32
		inline var off_dxgiFormat = 0;

		// Parse header
		var header = new Int32Array(buffer, 0, headerLengthInt);
		if (header[off_magic] != DDS_MAGIC) {
			trace('THREE.DDSLoader.parse: Invalid magic number in DDS header.');
			return dds;
		}
		var blockBytes = 0;
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
				if (header[off_RGBBitCount] == 32 && (header[off_RBitMask] & 0xff0000) != 0 && (header[off_GBitMask] & 0xff00) != 0
					&& (header[off_BBitMask] & 0xff) != 0 && (header[off_ABitMask] & 0xff000000) != 0) {
					isRGBAUncompressed = true;
					blockBytes = 64;
					dds.format = RGBAFormat;
				} else {
					trace('THREE.DDSLoader.parse: Unsupported FourCC code ' + int32ToFourCC(fourCC));
					return dds;
				}
		}
		dds.mipmapCount = 1;
		if ((header[off_flags] & DDSD_MIPMAPCOUNT) != 0 && loadMipmaps != false) {
			dds.mipmapCount = Math.max(1, header[off_mipmapCount]);
		}
		var caps2 = header[off_caps2];
		dds.isCubemap = (caps2 & DDSCAPS2_CUBEMAP) != 0;
		if (dds.isCubemap
			&& ((caps2 & DDSCAPS2_CUBEMAP_POSITIVEX) == 0 || (caps2 & DDSCAPS2_CUBEMAP_NEGATIVEX) == 0 || (caps2 & DDSCAPS2_CUBEMAP_POSITIVEY) == 0
				|| (caps2 & DDSCAPS2_CUBEMAP_NEGATIVEY) == 0 || (caps2 & DDSCAPS2_CUBEMAP_POSITIVEZ) == 0
				|| (caps2 & DDSCAPS2_CUBEMAP_NEGATIVEZ) == 0)) {
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
				var byteArray:Uint8Array = null;
				var dataLength = 0;
				if (isRGBAUncompressed) {
					byteArray = loadARGBMip(new Uint8Array(buffer), dataOffset, width, height);
					dataLength = byteArray.length;
				} else {
					dataLength = Math.max(4, width) / 4 * Math.max(4, height) / 4 * blockBytes;
					byteArray = new Uint8Array(buffer, dataOffset, dataLength);
				}
				var mipmap = {data: byteArray, width: width, height: height};
				dds.mipmaps.push(mipmap);
				dataOffset += dataLength;
				width = Math.max(width >> 1, 1);
				height = Math.max(height >> 1, 1);
			}
		}
		return dds;
	}
}